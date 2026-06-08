//
//  DummyMemoryActivityProvider.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//

import Foundation

enum DummyMemoryActivityProvider {
    static func activities(for memories: [Memory]) -> [String: MemoryActivity] {
        let dummyUsers = [
            ("alex", "Alex", "person.crop.circle.fill"),
            ("jisu", "Jisu", "person.crop.circle.badge.checkmark"),
            ("mia", "Mia", "face.smiling.fill"),
            ("ben", "Ben", "person.fill")
        ]

        let dummyEmojis = ["😍", "🔥", "😋", "❤️", "🥹", "✨"]

        var result: [String: MemoryActivity] = [:]

        for (index, memory) in memories.enumerated() {
            // Only give some bubbles activity, not all of them.
            // This makes the board feel more natural.
            guard index % 2 == 0 || index == 1 else {
                continue
            }

            let user = dummyUsers[index % dummyUsers.count]

            let isReaction = index % 3 != 1

            result[memory.id] = MemoryActivity(
                memoryId: memory.id,
                albumId: memory.albumId,
                userId: user.0,
                userDisplayName: user.1,
                userIconSystemName: user.2,
                emoji: isReaction ? dummyEmojis[index % dummyEmojis.count] : nil,
                activityType: isReaction ? .reaction : .visit,
                createdAt: Date().addingTimeInterval(Double(-index * 180))
            )
        }

        return result
    }
}
