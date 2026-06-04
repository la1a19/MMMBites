//
//  Tag.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation
import FirebaseFirestore

struct Tag: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore doc ID for this tag
    var name: String             // label shown in the UI (e.g. "dessert", "best")
    var albumID: String          // ID of the album this tag belongs to
}
