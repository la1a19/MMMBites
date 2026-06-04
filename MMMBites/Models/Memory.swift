//
//  Memory.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation
import FirebaseFirestore

struct Memory: Identifiable, Codable {
    @DocumentID var id: String?      // Firestore doc ID for this memory
    var title: String                // short name for the memory (e.g. "Tiramisu at Lune")
    var note: String?                // optional longer description / journal entry
    var photoURLs: [String]          // Firebase Storage URLs for the attached photos
    var albumID: String              // ID of the album this memory belongs to
    var location: String?            // optional place name (restaurant, city, etc.)
    var createdBy: String            // UID of the user who added this memory
    @ServerTimestamp var date: Date? // when the memory was logged (server time)
}
