//
//  Untitled.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//

import Foundation

enum MemoryActivityType: String, Codable {
    case visit
    case reaction
}

struct MemoryActivity: Identifiable, Codable {
    var id: String = UUID().uuidString

    var memoryId: String
    var albumId: String?

    var userId: String
    var userDisplayName: String
    var userIconSystemName: String

    var emoji: String?
    var activityType: MemoryActivityType

    var createdAt: Date = Date()
}
