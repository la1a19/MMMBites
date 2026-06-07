//
//  Album.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation

struct Album: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var description: String?
    var coverImageURL: String?
    var coverPhotoData: Data?
    var ownerId: String
    var tags: [String]
    var location: String?
    var latitude: Double?          // coordinate (filled by MapKit autocomplete)
    var longitude: Double?
    var date: Date?
    var friendIds: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        coverImageURL: String? = nil,
        coverPhotoData: Data? = nil,
        ownerId: String,
        tags: [String] = [],
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        date: Date? = nil,
        friendIds: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageURL = coverImageURL
        self.coverPhotoData = coverPhotoData
        self.ownerId = ownerId
        self.tags = tags
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.friendIds = friendIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
