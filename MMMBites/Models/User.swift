//
//  User.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import Foundation

struct User: Identifiable, Codable {
    let id : String
    var username : String
    var displayName : String
    var friendIDs : [String]
}
