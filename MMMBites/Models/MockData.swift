//
//  MockData.swift
//  MMMBites
//
//  Centralised mock albums + memories used across the views so that
//  cross-album similarity, recap sentences, and the map preview all
//  work with realistic, presentation-friendly data.
//

import Foundation

enum MockData {

    // MARK: - Albums (stable string ids so memory.albumId == album.id)

    static let albumPark = Album(
        id: "park",
        title: "Park",
        ownerId: "jisu",
        tags: ["Picnic", "Outdoor", "Brunch"],
        location: "Centennial Park, Sydney",
        date: daysAgo(7),
        friendIds: ["Jisu", "Ada", "Tin"]
    )

    static let albumComfort = Album(
        id: "comfort",
        title: "Comfort Food",
        ownerId: "jisu",
        tags: ["Italian", "Dinner", "Home Cooking"],
        location: "Surry Hills, Sydney",
        date: daysAgo(12),
        friendIds: ["Jisu", "Mia"]
    )

    static let albumFun = Album(
        id: "fun",
        title: "Fun Meals",
        ownerId: "jisu",
        tags: ["Korean", "Dinner", "Late Night"],
        location: "Haymarket, Sydney",
        date: daysAgo(18),
        friendIds: ["Jisu", "Tin", "Leo"]
    )

    static let albumSpecial = Album(
        id: "special",
        title: "Special Moments",
        ownerId: "jisu",
        tags: ["Birthday", "Dessert", "Celebration"],
        location: "Newtown, Sydney",
        date: daysAgo(3),
        friendIds: ["Jisu", "Ada", "Mia"]
    )

    static let allAlbums: [Album] = [albumPark, albumComfort, albumFun, albumSpecial]

    // MARK: - Memories

    static let allMemories: [Memory] = [
        // 1) Picnic Fun — Park
        Memory(
            albumId: "park",
            title: "Picnic Fun",
            note: "Snacks under the trees with the gang. Light wind, bigger laughs, and somehow every bite tasted better outdoors.",
            location: "Centennial Park, Sydney",
            latitude: -33.8950,
            longitude: 151.2333,
            capturedById: "Jisu",
            reactions: [
                Reaction(userId: "jisu", emoji: "🧺"),
                Reaction(userId: "ada",  emoji: "😂"),
                Reaction(userId: "tin",  emoji: "🫶"),
                Reaction(userId: "jisu", emoji: "✨")
            ],
            mood: .chill,
            bestBite: "Fairy bread",
            memorableTags: ["Friends", "Atmosphere", "Food"],
            participantIds: ["Jisu", "Ada", "Tin"],
            date: daysAgo(7)
        ),

        // 2) Sunset Snacks — Park (very similar to #1)
        Memory(
            albumId: "park",
            title: "Sunset Snacks",
            note: "Watched the sky turn pink. Hardly said anything — the quiet was the best part.",
            location: "Centennial Park, Sydney",
            latitude: -33.8950,
            longitude: 151.2333,
            capturedById: "Jisu",
            reactions: [
                Reaction(userId: "jisu", emoji: "🥹"),
                Reaction(userId: "ada",  emoji: "✨"),
                Reaction(userId: "jisu", emoji: "🍓")
            ],
            mood: .chill,
            bestBite: "Strawberries",
            memorableTags: ["Atmosphere", "Conversation"],
            participantIds: ["Jisu", "Ada"],
            date: daysAgo(6)
        ),

        // 3) Cozy Pasta Night — Comfort Food
        Memory(
            albumId: "comfort",
            title: "Cozy Pasta Night",
            note: "Carbonara, dim lights, and that long talk about everything and nothing.",
            location: "Surry Hills, Sydney",
            latitude: -33.8867,
            longitude: 151.2106,
            capturedById: "Jisu",
            reactions: [
                Reaction(userId: "jisu", emoji: "😋"),
                Reaction(userId: "mia",  emoji: "🫶"),
                Reaction(userId: "jisu", emoji: "☕️")
            ],
            mood: .cozy,
            bestBite: "Cream pasta",
            memorableTags: ["Food", "Conversation", "Atmosphere"],
            participantIds: ["Jisu", "Mia"],
            date: daysAgo(12)
        ),

        // 4) Spicy Noodle Challenge — Fun Meals
        Memory(
            albumId: "fun",
            title: "Spicy Noodle Challenge",
            note: "Tin couldn't feel his tongue. Leo cried twice. Worth it.",
            location: "Haymarket, Sydney",
            latitude: -33.8800,
            longitude: 151.2050,
            capturedById: "Tin",
            reactions: [
                Reaction(userId: "jisu", emoji: "🌶️"),
                Reaction(userId: "tin",  emoji: "😂"),
                Reaction(userId: "leo",  emoji: "🤤")
            ],
            mood: .chaotic,
            bestBite: "Spicy noodles",
            memorableTags: ["Friends", "Surprise", "Food"],
            participantIds: ["Jisu", "Tin", "Leo"],
            date: daysAgo(18)
        ),

        // 5) Birthday Dessert — Special Moments
        Memory(
            albumId: "special",
            title: "Birthday Dessert",
            note: "Ada brought a cake out of nowhere. Mia stuck a sparkler in it. Worth a whole month.",
            location: "Newtown, Sydney",
            latitude: -33.8975,
            longitude: 151.1797,
            capturedById: "Jisu",
            reactions: [
                Reaction(userId: "jisu", emoji: "🥹"),
                Reaction(userId: "ada",  emoji: "🍰"),
                Reaction(userId: "mia",  emoji: "✨"),
                Reaction(userId: "jisu", emoji: "🫶")
            ],
            mood: .special,
            bestBite: "Strawberry cake",
            memorableTags: ["Friends", "Surprise", "Food"],
            participantIds: ["Jisu", "Ada", "Mia"],
            date: daysAgo(3)
        )
    ]

    // MARK: - Lookups

    static func memories(forAlbumId id: String) -> [Memory] {
        allMemories.filter { $0.albumId == id }
    }

    static func memories(excludingAlbumId id: String) -> [Memory] {
        allMemories.filter { $0.albumId != id }
    }

    static func album(id: String) -> Album? {
        allAlbums.first { $0.id == id }
    }

    // MARK: - Helpers

    private static func daysAgo(_ d: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -d, to: Date()) ?? Date()
    }
}
