//
//  Tag.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation
import FirebaseFirestore

struct Tag: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var colorHex: String
    var ownerId: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        colorHex: String,
        ownerId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.ownerId = ownerId
        self.createdAt = createdAt
    }
}
