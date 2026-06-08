//
//  MemoryActivityService.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//

import Foundation

@MainActor
protocol MemoryActivityProviding {
    func latestActivities(for memories: [Memory]) async -> [String: MemoryActivity]
}
