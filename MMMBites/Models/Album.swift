//
//  Album.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation

struct Album: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String?
    var coverImageURL: String?
    var ownerId: String
    var tags: [String]
    var location: String?          // added: e.g. "SupaFancy Resto, Sydney"
    var date: Date?                // added: the album's event date (June 3, 2067)
    var friendIds: [String]        // added: ids of tagged friends
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        coverImageURL: String? = nil,
        ownerId: String,
        tags: [String] = [],
        location: String? = nil,
        date: Date? = nil,
        friendIds: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageURL = coverImageURL
        self.ownerId = ownerId
        self.tags = tags
        self.location = location
        self.date = date
        self.friendIds = friendIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
