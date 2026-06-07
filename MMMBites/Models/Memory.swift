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
    case chill, fun, cozy, special, chaotic, comfort, fancy, adventurous

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? Self.legacyMoodMap[rawValue] ?? .special
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static let legacyMoodMap: [String: MemoryMood] = [
        "mellow": .chill,
        "peaceful": .chill,
        "warm": .cozy,
        "intimate": .cozy,
        "playful": .fun,
        "silly": .fun,
        "buzzing": .fun,
        "spontaneous": .adventurous,
        "curious": .adventurous,
        "romantic": .special,
        "nostalgic": .special,
        "sentimental": .special,
        "grateful": .special,
        "dreamy": .special,
        "proud": .special,
        "refreshing": .comfort
    ]

    var label: String {
        switch self {
        case .chill:        return "Chill"
        case .fun:          return "Fun"
        case .cozy:         return "Cozy"
        case .special:      return "Special"
        case .chaotic:      return "Chaotic"
        case .comfort:      return "Comfort"
        case .adventurous:  return "Adventurous"
        case .fancy:        return "Fancy"
        }
    }

    var emoji: String {
        switch self {
        case .chill:        return "😌"
        case .fun:          return "🎉"
        case .cozy:         return "🫖"
        case .special:      return "✨"
        case .chaotic:      return "🌪️"
        case .comfort:      return "🍲"
        case .adventurous:  return "🧭"
        case .fancy:        return "🥂"
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

    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // photoData stays in-memory only — Firestore documents have a 1 MiB
    // limit and even one photo blows past it, which previously caused the
    // whole memory to fail to save.
    enum CodingKeys: String, CodingKey {
        case id, albumId, title, note, imageURLs, location, latitude, longitude
        case capturedById, reactions, mood, bestBite, memorableTags, participantIds
        case isFavourite, date, createdAt, updatedAt
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
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Recap

extension Memory {
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
