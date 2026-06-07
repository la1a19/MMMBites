//
//  MemorySimilarity.swift
//  MMMBites
//
//  Lightweight recommendation logic for "Similar memories".
//

import Foundation

/// A memory recommended in the Similar memories rail, bundled with its album
/// so navigation can supply the right title.
struct SimilarMemoryEntry: Identifiable {
    let memory: Memory
    let album: Album
    let score: Int
    var id: String { memory.id }
}

enum MemorySimilarity {
    /// Simple MVP scoring:
    /// - Same mood: +3
    /// - Each shared memorable tag: +2
    ///
    /// Album, people, location, and recency are intentionally not part of the
    /// score so the rail remains easy to explain: similar feeling or reason.
    nonisolated static func similarityScore(candidate: Memory, current: Memory) -> Int {
        var score = 0

        if let currentMood = current.mood,
           let candidateMood = candidate.mood,
           currentMood == candidateMood {
            score += 3
        }

        score += sharedMemorableTagCount(candidate: candidate, current: current) * 2
        return score
    }

    nonisolated static func similarMemories(
        for current: Memory,
        in currentAlbum: Album,
        allMemories: [Memory],
        allAlbums: [Album],
        limit: Int = 3
    ) -> [SimilarMemoryEntry] {
        let albumLookup = Dictionary(uniqueKeysWithValues: allAlbums.map { ($0.id, $0) })

        return allMemories
            .filter { $0.id != current.id }
            .compactMap { candidate -> SimilarMemoryEntry? in
                guard let album = albumLookup[candidate.albumId] else { return nil }
                let score = similarityScore(candidate: candidate, current: current)
                guard score > 0 else { return nil }
                return SimilarMemoryEntry(memory: candidate, album: album, score: score)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.memory.date > rhs.memory.date
            }
            .prefix(limit)
            .map { $0 }
    }

    private nonisolated static func sharedMemorableTagCount(candidate: Memory, current: Memory) -> Int {
        let currentTags = Set(current.memorableTags.map(normalizedTag(_:)))
        let candidateTags = Set(candidate.memorableTags.map(normalizedTag(_:)))
        return currentTags.intersection(candidateTags).count
    }

    private nonisolated static func normalizedTag(_ tag: String) -> String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
