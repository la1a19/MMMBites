//
//  Album.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation
import FirebaseFirestore

struct Album: Identifiable, Codable {
    @DocumentID var id: String?           // Firestore doc ID for this album
    var title: String                     // album name shown in the UI
    //short description of album
    var coverURL: String?                 // optional cover photo (Firebase Storage URL)
    var memberIDs: [String]               // UIDs of users who can view/edit this album
    var tagIDs: [String]                  // IDs of tags applied to this album
    var createdBy: String                 // UID of the user who created the album
    @ServerTimestamp var createdAt: Date? // when the album was created (server time)
    //updated at
}
