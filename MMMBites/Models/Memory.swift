//
//  Memory.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation

// MARK: - Mood & memorable reasons

/// How the meal/experience felt.
enum MemoryMood: String, Codable, CaseIterable, Identifiable {
    case fun, cozy, fancy, relaxing, heartwarming, celebratory, casual, nostalgic, chaotic, disappointing

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? Self.legacyMoodMap[rawValue] ?? .fun
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static let legacyMoodMap: [String: MemoryMood] = [
        "chill": .relaxing,
        "mellow": .relaxing,
        "peaceful": .relaxing,
        "warm": .heartwarming,
        "intimate": .heartwarming,
        "special": .celebratory,
        "comfort": .heartwarming,
        "adventurous": .fun,
        "playful": .fun,
        "silly": .fun,
        "buzzing": .fun,
        "spontaneous": .fun,
        "curious": .fun,
        "romantic": .heartwarming,
        "sentimental": .nostalgic,
        "grateful": .heartwarming,
        "dreamy": .nostalgic,
        "proud": .celebratory,
        "refreshing": .relaxing
    ]

    var label: String {
        switch self {
        case .fun:           return "Fun"
        case .cozy:          return "Cozy"
        case .fancy:         return "Fancy"
        case .relaxing:      return "Relaxing"
        case .heartwarming:  return "Heartwarming"
        case .celebratory:   return "Celebratory"
        case .casual:        return "Casual"
        case .nostalgic:     return "Nostalgic"
        case .chaotic:       return "Chaotic"
        case .disappointing: return "Disappointing"
        }
    }

    var emoji: String {
        switch self {
        case .fun:           return "🎉"
        case .cozy:          return "🫖"
        case .fancy:         return "🥂"
        case .relaxing:      return "😌"
        case .heartwarming:  return "💛"
        case .celebratory:   return "✨"
        case .casual:        return "🍽️"
        case .nostalgic:     return "📸"
        case .chaotic:       return "🌪️"
        case .disappointing: return "😕"
        }
    }
}

/// Predefined defaults shown as quick-pick suggestions in the
/// "What made it memorable" input. Memories store the raw label strings
/// in `memorableTags`, so users can also add their own.
enum MemorableReasonDefault: String, CaseIterable {
    case food, friends, place, conversation, atmosphere, surprise

    var label: String {
        switch self {
        case .food:          return "Food"
        case .friends:       return "Friends"
        case .place:         return "Place"
        case .conversation:  return "Conversation"
        case .atmosphere:    return "Atmosphere"
        case .surprise:      return "Surprise"
        }
    }

    static var allLabels: [String] {
        allCases.map(\.label)
    }
}

// MARK: - Memory

struct Memory: Identifiable, Codable {
    var id: String = UUID().uuidString
    var albumId: String
    var title: String
    var note: String?
    var imageURLs: [String]
    var photoData: [Data] = []         // locally picked photos (PhotosPicker) — never persisted
    var location: String?
    var latitude: Double?              // coordinate for map preview
    var longitude: Double?
    var capturedById: String?
    var reactions: [Reaction]

    // Experience metadata
    var mood: MemoryMood?
    var bestBite: String?
    var memorableTags: [String]
    var participantIds: [String]

    // Optional so older Firestore docs without the field still decode.
    var isFavourite: Bool?

    // Friend-selected memorable reasons. Optional for older Firestore docs.
    var friendMemorableTags: [FriendMemorableTag]?

    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // photoData stays in-memory only — Firestore documents have a 1 MiB
    // limit and even one photo blows past it, which previously caused the
    // whole memory to fail to save.
    enum CodingKeys: String, CodingKey {
        case id, albumId, title, note, imageURLs, location, latitude, longitude
        case capturedById, reactions, mood, bestBite, memorableTags, participantIds
        case isFavourite, friendMemorableTags, date, createdAt, updatedAt
    }

    init(
        id: String = UUID().uuidString,
        albumId: String,
        title: String,
        note: String? = nil,
        imageURLs: [String] = [],
        photoData: [Data] = [],
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        capturedById: String? = nil,
        reactions: [Reaction] = [],
        mood: MemoryMood? = nil,
        bestBite: String? = nil,
        memorableTags: [String] = [],
        participantIds: [String] = [],
        isFavourite: Bool? = nil,
        friendMemorableTags: [FriendMemorableTag]? = nil,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.note = note
        self.imageURLs = imageURLs
        self.photoData = photoData
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.capturedById = capturedById
        self.reactions = reactions
        self.mood = mood
        self.bestBite = bestBite
        self.memorableTags = memorableTags
        self.participantIds = participantIds
        self.isFavourite = isFavourite
        self.friendMemorableTags = friendMemorableTags
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Recap

extension Memory {
    func includesUser(_ userID: String) -> Bool {
        capturedById == userID || participantIds.contains(userID)
    }

    /// Short human-readable sentence that explains why this memory mattered.
    /// Generated from mood + people + location + memorable reasons.
    var recapSentence: String {
        recapSentence(nameFor: { $0 })
    }

    /// Same as `recapSentence`, but maps participant IDs through `nameFor`
    /// so the rendered names are usernames (or whatever the caller resolves).
    func recapSentence(nameFor: (String) -> String) -> String {
        var parts: [String] = []

        let moodWord = mood?.label.lowercased() ?? "moment"
        parts.append("A \(moodWord) memory")

        if !participantIds.isEmpty {
            let names = friendlyJoin(participantIds.prefix(3).map(nameFor))
            parts.append("with \(names)")
        }

        if let location, !location.isEmpty {
            parts.append("at \(location)")
        }

        if !memorableTags.isEmpty {
            let labels = memorableTags.prefix(3).map { $0.lowercased() }
            parts.append(", remembered for \(friendlyJoin(labels))")
        }

        // Join parts with spaces but no space before the comma part.
        var sentence = parts[0]
        for p in parts.dropFirst() {
            if p.hasPrefix(",") {
                sentence += p
            } else {
                sentence += " " + p
            }
        }
        return sentence + "."
    }

    private func friendlyJoin(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        case 2: return "\(items[0]) and \(items[1])"
        default:
            let head = items.dropLast().joined(separator: ", ")
            return "\(head), and \(items.last!)"
        }
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
/// A memorable reason selected by a friend after the memory is created.
/// Users can choose as many tags as they want; each user/tag pair is unique.
struct FriendMemorableTag: Identifiable, Codable, Hashable {
    var userId: String
    var username: String
    var avatarData: String?
    var tag: String
    var createdAt: Date

    var id: String { "\(userId)-\(tag)" }

    init(
        userId: String,
        username: String,
        avatarData: String? = nil,
        tag: String,
        createdAt: Date = Date()
    ) {
        self.userId = userId
        self.username = username
        self.avatarData = avatarData
        self.tag = tag
        self.createdAt = createdAt
    }
}
