//
//  Memory.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//


import Foundation

struct Memory: Identifiable, Codable {
    var id: String = UUID().uuidString
    var albumId: String
    var title: String
    var note: String?
    var imageURLs: [String]          // changed: now multiple photos
    var location: String?            // added
    var capturedById: String?        // added: who created this memory (User id)
    var reactions: [Reaction]        // added: who reacted and how
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        albumId: String,
        title: String,
        note: String? = nil,
        imageURLs: [String] = [],
        location: String? = nil,
        capturedById: String? = nil,
        reactions: [Reaction] = [],
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.note = note
        self.imageURLs = imageURLs
        self.location = location
        self.capturedById = capturedById
        self.reactions = reactions
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// A single reaction: which user reacted with which emoji
struct Reaction: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userId: String       // who reacted
    var emoji: String        // e.g. "❤️", "😋"

    init(id: String = UUID().uuidString, userId: String, emoji: String) {
        self.id = id
        self.userId = userId
        self.emoji = emoji
    }
}
