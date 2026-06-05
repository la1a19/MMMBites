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
    var username: String                  // unique handle used to find/add friends
    var displayName: String               // user-facing name (can have spaces / emoji)
    var avatarURL: String?                // profile picture, Firebase Storage URL
    var friendIDs: [String]               // UIDs of confirmed friends
    @ServerTimestamp var createdAt: Date? // when the account was created (server time)
}
