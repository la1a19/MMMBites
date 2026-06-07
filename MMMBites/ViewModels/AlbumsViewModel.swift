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
    @Published var memoryCount = 0
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasInitiallyLoaded = false

    private let database = Firestore.firestore()

    // Firestore can't OR across fields, so we run two listeners
    // (owner + friend) and merge their results into `albums`.
    private var ownedListener: ListenerRegistration?
    private var friendListener: ListenerRegistration?
    private var ownedAlbums: [String: Album] = [:]
    private var friendAlbums: [String: Album] = [:]
    private var memoryCountListeners: [ListenerRegistration] = []
    private var memoryCountsByChunk: [Int: Int] = [:]
    private var currentUserID: String?



    deinit {
        ownedListener?.remove()
        friendListener?.remove()
        memoryCountListeners.forEach { $0.remove() }
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
        memoryCountListeners.forEach { $0.remove() }
        memoryCountListeners = []
        memoryCountsByChunk = [:]
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
        startMemoryCountListeners(forAlbumIDs: albums.map(\.id))
    }

    private func startMemoryCountListeners(forAlbumIDs albumIDs: [String]) {
        memoryCountListeners.forEach { $0.remove() }
        memoryCountListeners = []
        memoryCountsByChunk = [:]
        memoryCount = 0

        guard !albumIDs.isEmpty else { return }

        for (index, chunk) in albumIDs.chunked(into: 30).enumerated() {
            let listener = database.collection("memories")
                .whereField("albumId", in: chunk)
                .addSnapshotListener { [weak self] snapshot, error in
                    Task { @MainActor in
                        guard let self else { return }
                        if let error {
                            print("[AlbumsViewModel] memory count error: \(error)")
                            self.errorMessage = error.localizedDescription
                            return
                        }
                        self.memoryCountsByChunk[index] = snapshot?.documents.count ?? 0
                        self.memoryCount = self.memoryCountsByChunk.values.reduce(0, +)
                    }
                }
            memoryCountListeners.append(listener)
        }
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
                errorMessage = error.localizedDescription
            }
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
