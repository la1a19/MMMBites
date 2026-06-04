//
//  Album.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

//
//  Album.swift
//  MMMBites
//

import Foundation
import FirebaseFirestore

struct Album: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String?
    var coverImageURL: String?
    var ownerId: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        coverImageURL: String? = nil,
        ownerId: String,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageURL = coverImageURL
        self.ownerId = ownerId
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
