//
//  MemoriesViewModel.swift
//  MMMBites
//
//  Loads/saves memories for a single album from Firestore.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MemoriesViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let database = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var currentAlbumID: String?

    deinit {
        listener?.remove()
    }

    func startListening(forAlbumID id: String) {
        guard id != currentAlbumID || listener == nil else { return }
        listener?.remove()
        currentAlbumID = id
        isLoading = true

        listener = database.collection("memories")
            .whereField("albumId", isEqualTo: id)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        print("[MemoriesViewModel] listen error: \(error)")
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    let decoded: [Memory] = snapshot?.documents.compactMap { doc in
                        do {
                            var memory = try doc.data(as: Memory.self)
                            // Restore locally cached photo bytes whenever the
                            // doc still lacks Storage URLs (slow/failed upload).
                            if memory.imageURLs.isEmpty {
                                memory.photoData = LocalPhotoCache.loadMemoryPhotos(memoryID: memory.id)
                            }
                            return memory
                        } catch {
                            print("[MemoriesViewModel] decode error for \(doc.documentID): \(error)")
                            return nil
                        }
                    } ?? []
                    self.memories = decoded.sorted { $0.date > $1.date }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        currentAlbumID = nil
        memories = []
    }

    func add(_ memory: Memory) async {
        var stored = memory
        let pickedPhotos = stored.photoData
        stored.photoData = []

        // Write the picked photos to disk first so the thumbnail survives
        // navigation and app restarts, regardless of whether the Storage
        // upload succeeds. Then save the metadata doc and try to upload.
        if !pickedPhotos.isEmpty {
            LocalPhotoCache.saveMemoryPhotos(pickedPhotos, memoryID: stored.id)
            var optimistic = memory
            optimistic.photoData = pickedPhotos
            upsertLocalMemory(optimistic)
        }

        do {
            try database.collection("memories").document(stored.id).setData(from: stored)
        } catch {
            print("[MemoriesViewModel] add error: \(error)")
            errorMessage = error.localizedDescription
            return
        }

        guard !pickedPhotos.isEmpty else { return }
        await uploadPhotos(pickedPhotos, for: stored.id)
    }

    func update(_ memory: Memory) async {
        var updated = memory
        let pickedPhotos = updated.photoData
        updated.photoData = []
        updated.updatedAt = Date()

        if !pickedPhotos.isEmpty {
            LocalPhotoCache.saveMemoryPhotos(pickedPhotos, memoryID: updated.id)
            var optimistic = memory
            optimistic.photoData = pickedPhotos
            upsertLocalMemory(optimistic)
        }

        do {
            try database.collection("memories").document(updated.id).setData(from: updated, merge: true)
        } catch {
            print("[MemoriesViewModel] update error: \(error)")
            errorMessage = error.localizedDescription
            return
        }

        guard !pickedPhotos.isEmpty else { return }
        await uploadPhotos(pickedPhotos, for: updated.id)
    }

    private func uploadPhotos(_ data: [Data], for memoryID: String) async {
        do {
            let urls = try await PhotoStorage.uploadMemoryPhotos(data, memoryID: memoryID)
            try await database.collection("memories").document(memoryID).setData(
                [
                    "imageURLs": urls,
                    "updatedAt": Timestamp(date: Date())
                ],
                merge: true
            )
            // Storage now has durable URLs — disk cache is no longer needed.
            LocalPhotoCache.clearMemoryPhotos(memoryID: memoryID)
        } catch {
            print("[MemoriesViewModel] photo upload error: \(error)")
            if !PhotoStorage.isMissingObjectError(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func remove(_ memory: Memory) async {
        do {
            try await database.collection("memories").document(memory.id).delete()
            await PhotoStorage.deleteMemoryPhotos(memoryID: memory.id)
            LocalPhotoCache.clearMemoryPhotos(memoryID: memory.id)
        } catch {
            print("[MemoriesViewModel] remove error: \(error)")
            if !PhotoStorage.isMissingObjectError(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func upsertLocalMemory(_ memory: Memory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
        } else {
            memories.insert(memory, at: 0)
        }
        memories.sort { $0.date > $1.date }
    }

}
