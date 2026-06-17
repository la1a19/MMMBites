//
//  AlbumsViewModel.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AlbumsViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var memories: [Memory] = []
    @Published var memoryCount = 0
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasInitiallyLoaded = false
    @Published var ownerUsers: [String: User] = [:]

    private let database = Firestore.firestore()

    // Firestore can't OR across fields, so we run two listeners
    // (owner + friend) and merge their results into `albums`.
    private var ownedListener: ListenerRegistration?
    private var friendListener: ListenerRegistration?
    private var ownedAlbums: [String: Album] = [:]
    private var friendAlbums: [String: Album] = [:]
    private var memoryListeners: [ListenerRegistration] = []
    private var memoriesByChunk: [Int: [Memory]] = [:]
    private var currentUserID: String?



    deinit {
        ownedListener?.remove()
        friendListener?.remove()
        memoryListeners.forEach { $0.remove() }
    }

    /// Listen to albums where the user is the owner OR is tagged as a friend.
    func startListening(for userID: String) {
        guard userID != currentUserID || (ownedListener == nil && friendListener == nil) else { return }
        stopListening()
        currentUserID = userID
        isLoading = true

        ownedListener = database.collection("albums")
            .whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    self?.handleSnapshot(snapshot, error: error, into: \.ownedAlbums)
                }
            }

        friendListener = database.collection("albums")
            .whereField("friendIds", arrayContains: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    self?.handleSnapshot(snapshot, error: error, into: \.friendAlbums)
                }
            }
    }

    func stopListening() {
        ownedListener?.remove()
        friendListener?.remove()
        ownedListener = nil
        friendListener = nil
        memoryListeners.forEach { $0.remove() }
        memoryListeners = []
        memoriesByChunk = [:]
        memories = []
        memoryCount = 0
        currentUserID = nil
        ownedAlbums = [:]
        friendAlbums = [:]
        albums = []
        hasInitiallyLoaded = false
    }

    private func handleSnapshot(
        _ snapshot: QuerySnapshot?,
        error: Error?,
        into bucket: ReferenceWritableKeyPath<AlbumsViewModel, [String: Album]>
    ) {
        isLoading = false
        if let error {
            print("[AlbumsViewModel] listen error: \(error)")
            errorMessage = error.localizedDescription
            return
        }
        var byId: [String: Album] = [:]
        for doc in snapshot?.documents ?? [] {
            do {
                var album = try doc.data(as: Album.self)
                // Restore the cached cover bytes whenever the doc lacks a
                // Storage URL — keeps the bubble thumbnail filled in even
                // when uploads are slow or blocked.
                if album.coverImageURL == nil {
                    album.coverPhotoData = LocalPhotoCache.loadAlbumCover(albumID: album.id)
                }
                byId[album.id] = album
            } catch {
                print("[AlbumsViewModel] decode error for \(doc.documentID): \(error)")
            }
        }
        self[keyPath: bucket] = byId
        mergeAndPublish()
        hasInitiallyLoaded = true
    }

    private func mergeAndPublish() {
        var merged = ownedAlbums
        for (id, album) in friendAlbums where merged[id] == nil {
            merged[id] = album
        }
        albums = merged.values.sorted { $0.updatedAt > $1.updatedAt }
        startMemoryListeners(forAlbumIDs: albums.map(\.id))
        Task { await loadOwnerUsers() }
    }

    private func loadOwnerUsers() async {
        let neededIDs = Set(albums.map(\.ownerId)).subtracting(ownerUsers.keys)
        guard !neededIDs.isEmpty else { return }

        var loaded = ownerUsers
        for chunk in Array(neededIDs).chunked(into: 30) {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                for document in snapshot.documents {
                    if let user = try? document.data(as: User.self), let id = user.id {
                        loaded[id] = user
                    }
                }
            } catch {
                print("[AlbumsViewModel] owner load error: \(error)")
            }
        }
        ownerUsers = loaded
    }

    private func startMemoryListeners(forAlbumIDs albumIDs: [String]) {
        memoryListeners.forEach { $0.remove() }
        memoryListeners = []
        memoriesByChunk = [:]
        memories = []
        memoryCount = 0

        guard !albumIDs.isEmpty else { return }

        for (index, chunk) in albumIDs.chunked(into: 30).enumerated() {
            let listener = database.collection("memories")
                .whereField("albumId", in: chunk)
                .addSnapshotListener { [weak self] snapshot, error in
                    Task { @MainActor in
                        guard let self else { return }
                        if let error {
                            print("[AlbumsViewModel] memory listen error: \(error)")
                            self.errorMessage = error.localizedDescription
                            return
                        }
                        let decoded: [Memory] = snapshot?.documents.compactMap { doc in
                            guard var memory = try? doc.data(as: Memory.self) else { return nil }
                            // Mirror MemoriesViewModel: fall back to locally
                            // cached photo bytes when Storage URLs aren't set yet.
                            if memory.imageURLs.isEmpty {
                                memory.photoData = LocalPhotoCache.loadMemoryPhotos(memoryID: memory.id)
                            }
                            return memory
                        } ?? []
                        self.memoriesByChunk[index] = decoded
                        self.publishMergedMemories()
                    }
                }
            memoryListeners.append(listener)
        }
    }

    private func publishMergedMemories() {
        let merged = memoriesByChunk.values.flatMap { $0 }
        memories = merged.sorted { $0.date > $1.date }
        memoryCount = merged.count
    }

    func add(_ album: Album) async {
        var stored = album
        let pickedCover = stored.coverPhotoData
        stored.coverPhotoData = nil

        if let pickedCover {
            LocalPhotoCache.saveAlbumCover(pickedCover, albumID: stored.id)
        }

        do {
            try database.collection("albums").document(stored.id).setData(from: stored)
        } catch {
            print("[AlbumsViewModel] add error: \(error)")
            errorMessage = error.localizedDescription
            ToastCenter.shared.showError("Couldn't create album. Check your connection.")
            return
        }

        guard let pickedCover else { return }
        await uploadCover(pickedCover, for: stored.id)
    }

    func update(_ album: Album) async {
        var updated = album
        let pickedCover = updated.coverPhotoData
        updated.coverPhotoData = nil
        updated.updatedAt = Date()

        if let pickedCover {
            LocalPhotoCache.saveAlbumCover(pickedCover, albumID: updated.id)
        }

        do {
            try database.collection("albums").document(updated.id).setData(from: updated, merge: true)
        } catch {
            print("[AlbumsViewModel] update error: \(error)")
            errorMessage = error.localizedDescription
            ToastCenter.shared.showError("Couldn't update album. Try again.")
            return
        }

        guard let pickedCover else { return }
        await uploadCover(pickedCover, for: updated.id)
    }

    private func uploadCover(_ data: Data, for albumID: String) async {
        do {
            let url = try await PhotoStorage.uploadAlbumCover(data, albumID: albumID)
            try await database.collection("albums").document(albumID).setData(
                [
                    "coverImageURL": url,
                    "updatedAt": Timestamp(date: Date())
                ],
                merge: true
            )
            LocalPhotoCache.clearAlbumCover(albumID: albumID)
        } catch {
            print("[AlbumsViewModel] cover upload error: \(error)")
            if !PhotoStorage.isMissingObjectError(error) {
                errorMessage = error.localizedDescription
                ToastCenter.shared.showError("Cover photo upload failed. Album was saved.")
            }
        }
    }

    func remove(_ album: Album) async {
        do {
            let memoryIDs = try await deleteMemories(inAlbumID: album.id)
            try await database.collection("albums").document(album.id).delete()

            // Best-effort Storage + local cleanup.
            await PhotoStorage.deleteAlbumCover(albumID: album.id)
            LocalPhotoCache.clearAlbumCover(albumID: album.id)
            for id in memoryIDs {
                await PhotoStorage.deleteMemoryPhotos(memoryID: id)
                LocalPhotoCache.clearMemoryPhotos(memoryID: id)
            }
        } catch {
            print("[AlbumsViewModel] remove error: \(error)")
            if !PhotoStorage.isMissingObjectError(error) {
                let nsError = error as NSError
                let isPermissionDenied = nsError.domain == FirestoreErrorDomain
                    && nsError.code == FirestoreErrorCode.permissionDenied.rawValue
                if isPermissionDenied {
                    errorMessage = "This album has memories from friends. Ask them to delete their memories first, then try again."
                    ToastCenter.shared.showError("Friends' memories must be deleted first.")
                } else {
                    errorMessage = error.localizedDescription
                    ToastCenter.shared.showError("Couldn't delete album. Try again.")
                }
            }
        }
    }

    /// Replace `oldTag` with `newTag` on every owned album that uses it.
    /// Comparison is case-insensitive; new value is stored capitalized.
    func renameTagInAlbums(from oldTag: String, to newTag: String) async {
        guard let currentUserID else { return }
        let normalizedOld = oldTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNew = newTag.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
        guard !normalizedOld.isEmpty, !normalizedNew.isEmpty,
              normalizedOld.caseInsensitiveCompare(normalizedNew) != .orderedSame else { return }

        let affected = albums.filter { album in
            album.ownerId == currentUserID &&
            album.tags.contains { $0.caseInsensitiveCompare(normalizedOld) == .orderedSame }
        }
        guard !affected.isEmpty else { return }

        do {
            for chunk in affected.chunked(into: 400) {
                let batch = database.batch()
                for album in chunk {
                    let updatedTags = album.tags.map { tag -> String in
                        tag.caseInsensitiveCompare(normalizedOld) == .orderedSame ? normalizedNew : tag
                    }
                    let ref = database.collection("albums").document(album.id)
                    batch.updateData([
                        "tags": updatedTags,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: ref)
                }
                try await batch.commit()
            }
        } catch {
            print("[AlbumsViewModel] tag rename error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// Remove `tag` from every owned album that uses it (case-insensitive match).
    func removeTagFromAlbums(_ tag: String) async {
        guard let currentUserID else { return }
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        let affected = albums.filter { album in
            album.ownerId == currentUserID &&
            album.tags.contains { $0.caseInsensitiveCompare(normalized) == .orderedSame }
        }
        guard !affected.isEmpty else { return }

        do {
            for chunk in affected.chunked(into: 400) {
                let batch = database.batch()
                for album in chunk {
                    let updatedTags = album.tags.filter {
                        $0.caseInsensitiveCompare(normalized) != .orderedSame
                    }
                    let ref = database.collection("albums").document(album.id)
                    batch.updateData([
                        "tags": updatedTags,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: ref)
                }
                try await batch.commit()
            }
        } catch {
            print("[AlbumsViewModel] tag delete error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func deleteMemories(inAlbumID albumID: String) async throws -> [String] {
        let snapshot = try await database.collection("memories")
            .whereField("albumId", isEqualTo: albumID)
            .getDocuments()

        let memoryIDs = snapshot.documents.map(\.documentID)

        for chunk in snapshot.documents.chunked(into: 450) {
            let batch = database.batch()
            for document in chunk {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }
        return memoryIDs
    }
}
