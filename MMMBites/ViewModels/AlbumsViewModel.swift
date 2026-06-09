//
//  AlbumsViewModel.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//



import Foundation
import SwiftUI
import Combine

final class AlbumsViewModel: ObservableObject {
    @Published var albums: [Album]

    init(albums: [Album] = []) {
        if albums.isEmpty {
            self.albums = [
                Album(title: "PARK", ownerId: "jisu", tags: ["Tree", "nature", "Picnic"]),
                Album(title: "BEACH", ownerId: "jisu", tags: ["Sea", "Summer", "Fun"]),
                Album(title: "DINNER", ownerId: "jisu", tags: ["Fancy", "Family"])
            ]
        } else {
            self.albums = albums
        }
    }

    func add(_ album: Album) {
        albums.insert(album, at: 0)
    }

    func update(_ album: Album) {
        if let idx = albums.firstIndex(where: { $0.id == album.id }) {
            albums[idx] = album
        }
    }

    func remove(_ album: Album) {
        albums.removeAll { $0.id == album.id }
    }
}
