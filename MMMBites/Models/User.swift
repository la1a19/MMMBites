//
//  User.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var username: String
    var email: String?
    var avatarURL: String?
    var avatarData: String?
    var friendIDs: [String]
    var customTags: [String]
    @ServerTimestamp var createdAt: Date?

    init(
        id: String? = nil,
        username: String,
        email: String? = nil,
        avatarURL: String? = nil,
        avatarData: String? = nil,
        friendIDs: [String] = [],
        customTags: [String] = [],
        createdAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
        self.avatarData = avatarData
        self.friendIDs = friendIDs
        self.customTags = customTags
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case avatarURL
        case avatarData
        case friendIDs
        case customTags
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? "User"
        email = try container.decodeIfPresent(String.self, forKey: .email)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        avatarData = try container.decodeIfPresent(String.self, forKey: .avatarData)
        friendIDs = try container.decodeIfPresent([String].self, forKey: .friendIDs) ?? []
        customTags = try container.decodeIfPresent([String].self, forKey: .customTags) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
}
