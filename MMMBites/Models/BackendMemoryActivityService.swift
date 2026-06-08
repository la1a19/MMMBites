import Foundation

@MainActor
final class BackendMemoryActivityService: MemoryActivityProviding {
    func latestActivities(for memories: [Memory]) async -> [String: MemoryActivity] {
        guard AppFeatureFlags.useBackendMemoryActivity else {
            return [:]
        }

        // Backend is not connected yet.
        // Later, this function will fetch real activity from Firebase, Firestore, or your API.
        return [:]
    }
}
