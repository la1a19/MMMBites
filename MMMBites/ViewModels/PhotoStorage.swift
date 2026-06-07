//
//  PhotoStorage.swift
//  MMMBites
//
//  Uploads photo blobs to Firebase Storage and returns download URLs,
//  so Firestore documents only carry references — not raw image data.
//

import Foundation
import FirebaseAuth
import FirebaseStorage

enum PhotoStorage {

    enum StorageError: LocalizedError {
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You need to be signed in to upload photos."
            }
        }
    }

    private static let bucket = Storage.storage()

    static func isMissingObjectError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.localizedDescription.localizedCaseInsensitiveContains("does not exist")
        || nsError.localizedDescription.localizedCaseInsensitiveContains("object not found")
    }

    // MARK: - Memory photos

    /// Uploads each blob under `memories/{memoryID}/photo_{index}.jpg`
    /// and returns their download URLs in input order.
    static func uploadMemoryPhotos(
        _ data: [Data],
        memoryID: String
    ) async throws -> [String] {
        guard !data.isEmpty else { return [] }
        guard Auth.auth().currentUser != nil else {
            throw StorageError.notAuthenticated
        }

        var urls: [String] = []
        urls.reserveCapacity(data.count)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        for (index, blob) in data.enumerated() {
            let ref = bucket.reference(withPath: "memories/\(memoryID)/photo_\(index).jpg")
            _ = try await ref.putDataAsync(blob, metadata: metadata)
            let url = try await ref.downloadURL()
            urls.append(url.absoluteString)
        }
        return urls
    }

    /// Best-effort delete of every photo for a memory. Errors are swallowed
    /// (logged only) so a failed cleanup never blocks Firestore deletion.
    static func deleteMemoryPhotos(memoryID: String) async {
        let folder = bucket.reference(withPath: "memories/\(memoryID)")
        do {
            let listing = try await folder.listAll()
            for item in listing.items {
                do {
                    try await item.delete()
                } catch {
                    if !isMissingObjectError(error) {
                        print("[PhotoStorage] delete item error: \(error)")
                    }
                }
            }
        } catch {
            if !isMissingObjectError(error) {
                print("[PhotoStorage] list memory photos error: \(error)")
            }
        }
    }

    // MARK: - Album cover

    /// Uploads the cover photo under `albums/{albumID}/cover.jpg` and
    /// returns its download URL.
    static func uploadAlbumCover(
        _ data: Data,
        albumID: String
    ) async throws -> String {
        guard Auth.auth().currentUser != nil else {
            throw StorageError.notAuthenticated
        }
        let ref = bucket.reference(withPath: "albums/\(albumID)/cover.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    /// Best-effort delete of the cover photo for an album.
    static func deleteAlbumCover(albumID: String) async {
        let ref = bucket.reference(withPath: "albums/\(albumID)/cover.jpg")
        do {
            try await ref.delete()
        } catch {
            // Missing object is fine; there was just nothing to clean up.
            if !isMissingObjectError(error) {
                print("[PhotoStorage] delete album cover error: \(error)")
            }
        }
    }
}

// MARK: - Local photo cache

/// Persists picked photos to the Documents directory so they survive view
/// navigation and app restarts even if Firebase Storage upload fails or is
/// slow. The Firestore listener restores `photoData`/`coverPhotoData` from
/// this cache whenever the document arrives without download URLs.
enum LocalPhotoCache {
    private static let fileManager = FileManager.default

    private static var rootDirectory: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("PhotoCache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func memoryDirectory(for memoryID: String) -> URL {
        let dir = rootDirectory.appendingPathComponent("memories", isDirectory: true)
            .appendingPathComponent(memoryID, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func albumCoverURL(for albumID: String) -> URL {
        let dir = rootDirectory.appendingPathComponent("albums", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("\(albumID).jpg")
    }

    // MARK: Memory photos

    static func saveMemoryPhotos(_ photos: [Data], memoryID: String) {
        let dir = memoryDirectory(for: memoryID)
        clearMemoryPhotos(memoryID: memoryID)
        for (index, blob) in photos.enumerated() {
            let url = dir.appendingPathComponent("photo_\(index).jpg")
            try? blob.write(to: url, options: .atomic)
        }
    }

    static func loadMemoryPhotos(memoryID: String) -> [Data] {
        let dir = memoryDirectory(for: memoryID)
        guard
            let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return [] }
        let sorted = files
            .filter { $0.lastPathComponent.hasPrefix("photo_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return sorted.compactMap { try? Data(contentsOf: $0) }
    }

    static func clearMemoryPhotos(memoryID: String) {
        let dir = memoryDirectory(for: memoryID)
        guard
            let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return }
        for url in files {
            try? fileManager.removeItem(at: url)
        }
    }

    // MARK: Album cover

    static func saveAlbumCover(_ data: Data, albumID: String) {
        let url = albumCoverURL(for: albumID)
        try? data.write(to: url, options: .atomic)
    }

    static func loadAlbumCover(albumID: String) -> Data? {
        let url = albumCoverURL(for: albumID)
        return try? Data(contentsOf: url)
    }

    static func clearAlbumCover(albumID: String) {
        let url = albumCoverURL(for: albumID)
        try? fileManager.removeItem(at: url)
    }
}
