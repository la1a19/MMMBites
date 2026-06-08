//
//  FriendRequest.swift
//  MMMBites
//

import Foundation
import FirebaseFirestore

struct FriendRequest: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var fromUserId: String
    var toUserId: String
    var fromUsername: String
    var fromAvatarData: String?
    var toUsername: String
    var toAvatarData: String?
    @ServerTimestamp var createdAt: Date?

    init(
        id: String? = nil,
        fromUserId: String,
        toUserId: String,
        fromUsername: String,
        fromAvatarData: String? = nil,
        toUsername: String,
        toAvatarData: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.fromUsername = fromUsername
        self.fromAvatarData = fromAvatarData
        self.toUsername = toUsername
        self.toAvatarData = toAvatarData
        self.createdAt = createdAt
    }

    /// Deterministic ID lets us prevent duplicates and look up a specific
    /// pending request without an extra query.
    static func documentID(fromUserId: String, toUserId: String) -> String {
        "\(fromUserId)_\(toUserId)"
    }
}
