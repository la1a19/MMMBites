//
//  Memory.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation
import FirebaseFirestore

struct Memory: Identifiable, Codable {
    var id: String = UUID().uuidString
    var albumId: String
    var title: String
    var note: String?
    var imageURL: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        albumId: String,
        title: String,
        note: String? = nil,
        imageURL: String? = nil,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.note = note
        self.imageURL = imageURL
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
