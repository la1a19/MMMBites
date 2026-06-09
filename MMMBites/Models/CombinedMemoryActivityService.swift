//
//  Untitled.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//

import Foundation

@MainActor
final class CombinedMemoryActivityService: MemoryActivityProviding {
    private let demoService = DemoMemoryActivityService()
    private let backendService = BackendMemoryActivityService()

    func latestActivities(for memories: [Memory]) async -> [String: MemoryActivity] {
        var combinedActivities: [String: MemoryActivity] = [:]

        if AppFeatureFlags.useDemoMemoryActivity {
            let demoActivities = await demoService.latestActivities(for: memories)

            for (memoryId, activity) in demoActivities {
                combinedActivities[memoryId] = activity
            }
        }

        if AppFeatureFlags.useBackendMemoryActivity {
            let backendActivities = await backendService.latestActivities(for: memories)

            for (memoryId, activity) in backendActivities {
                // Backend activity should override fake demo activity
                // if they are for the same memory.
                combinedActivities[memoryId] = activity
            }
        }

        return combinedActivities
    }
}
