//
//  User.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//


import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?           // Firestore doc ID — same as the Firebase Auth UID
    var username: String                  // user-facing name / handle (only name field this app needs)
    var avatarURL: String?                // profile picture URL (used when on Firebase Storage)
    var avatarData: String?               // base64-encoded JPEG, used while on Spark (free) tier
    var friendIDs: [String]               // UIDs of confirmed friends
    @ServerTimestamp var createdAt: Date? // when the account was created (server time)
}
