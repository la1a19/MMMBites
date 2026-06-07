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
    case chill, fun, cozy, special, chaotic, comfort

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chill:    return "Chill"
        case .fun:      return "Fun"
        case .cozy:     return "Cozy"
        case .special:  return "Special"
        case .chaotic:  return "Chaotic"
        case .comfort:  return "Comfort"
        }
    }

    var emoji: String {
        switch self {
        case .chill:    return "😌"
        case .fun:      return "🎉"
        case .cozy:     return "🫖"
        case .special:  return "✨"
        case .chaotic:  return "🌪️"
        case .comfort:  return "🍲"
        }
    }
}

/// What made the experience worth remembering.
enum MemorableReason: String, Codable, CaseIterable, Identifiable {
    case food, friends, place, conversation, atmosphere, surprise

    var id: String { rawValue }

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

    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .friends:       return "person.2.fill"
        case .place:         return "mappin.and.ellipse"
        case .conversation:  return "bubble.left.and.bubble.right.fill"
        case .atmosphere:    return "sparkles"
        case .surprise:      return "gift.fill"
        }
    }
}

// MARK: - Memory

struct Memory: Identifiable, Codable {
    var id: String = UUID().uuidString
    var albumId: String
    var title: String
    var note: String?
    var imageURLs: [String]
    var photoData: [Data]              // locally picked photos (PhotosPicker)
    var location: String?
    var latitude: Double?              // coordinate for map preview
    var longitude: Double?
    var capturedById: String?
    var reactions: [Reaction]

    // Experience metadata
    var mood: MemoryMood?
    var bestBite: String?
    var memorableReasons: [MemorableReason]
    var participantIds: [String]

    var date: Date
    var createdAt: Date
    var updatedAt: Date

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
        memorableReasons: [MemorableReason] = [],
        participantIds: [String] = [],
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
        self.memorableReasons = memorableReasons
        self.participantIds = participantIds
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
        var parts: [String] = []

        let moodWord = mood?.label.lowercased() ?? "moment"
        parts.append("A \(moodWord) memory")

        if !participantIds.isEmpty {
            let names = friendlyJoin(Array(participantIds.prefix(3)))
            parts.append("with \(names)")
        }

        if let location, !location.isEmpty {
            parts.append("at \(location)")
        }

        if !memorableReasons.isEmpty {
            let reasonLabels = memorableReasons.prefix(3).map { $0.label.lowercased() }
            parts.append(", remembered for \(friendlyJoin(reasonLabels))")
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
