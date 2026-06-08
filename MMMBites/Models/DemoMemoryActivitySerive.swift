//
//  DemoMemoryActivitySerive.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//

import Foundation

@MainActor
final class DemoMemoryActivityService: MemoryActivityProviding {
    func latestActivities(for memories: [Memory]) async -> [String: MemoryActivity] {
        guard AppFeatureFlags.useDemoMemoryActivity else {
            return [:]
        }

        return DummyMemoryActivityProvider.activities(for: memories)
    }
}
