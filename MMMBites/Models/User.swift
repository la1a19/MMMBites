//
//  User.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//


import Foundation

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var email: String
    var avatarURL: String?
    var memoryCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        username: String,
        email: String,
        avatarURL: String? = nil,
        memoryCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
        self.memoryCount = memoryCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
