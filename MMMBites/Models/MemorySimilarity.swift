//
//  MemorySimilarity.swift
//  MMMBites
//
//  Scoring logic for "Similar memories" recommendations.
//

import Foundation

/// A memory recommended to be shown in the Similar memories rail,
/// bundled with its album so navigation can supply the right title.
struct SimilarMemoryEntry: Identifiable {
    let memory: Memory
    let album: Album
    let score: Int
    var id: String { memory.id }
}

enum MemorySimilarity {

    // MARK: - Score (per requirement)
    //
    //   Same album:                 +5
    //   Same mood:                  +4
    //   Same tag (each):            +3
    //   Same friend (each):         +2  (Album.friendIds + Memory.participantIds + capturedById)
    //   Same/nearby location:       +2
    //   Same memorable reason each: +2
    //   Date within 30d:            +1
    //
    static func similarityScore(
        candidate: Memory,
        candidateAlbum: Album,
        current: Memory,
        currentAlbum: Album
    ) -> Int {
        var score = 0

        // Same album
        if candidate.albumId == current.albumId {
            score += 5
        }

        // Same mood
        if let cMood = current.mood, let candMood = candidate.mood, cMood == candMood {
            score += 4
        }

        // Same tag (compare album tag sets, case-insensitive)
        let currentTags   = Set(currentAlbum.tags.map { $0.lowercased() })
        let candidateTags = Set(candidateAlbum.tags.map { $0.lowercased() })
        score += currentTags.intersection(candidateTags).count * 3

        // Same friend / participant / captured-by user.
        // Combines album.friendIds + memory.participantIds + memory.capturedById.
        let currentPeople = Set(
            currentAlbum.friendIds
            + current.participantIds
            + [current.capturedById].compactMap { $0 }
        )
        let candidatePeople = Set(
            candidateAlbum.friendIds
            + candidate.participantIds
            + [candidate.capturedById].compactMap { $0 }
        )
        score += currentPeople.intersection(candidatePeople).count * 2

        // Same / nearby location (case-insensitive, trimmed).
        // Also counts if either location string contains the other (handles "Surry Hills" ⊂ "Cafe, Surry Hills").
        if let cur = normalizedLocation(memory: current, album: currentAlbum),
           let cand = normalizedLocation(memory: candidate, album: candidateAlbum) {
            if cur == cand || cur.contains(cand) || cand.contains(cur) {
                score += 2
            }
        }

        // Same memorable reason (each)
        let currentReasons = Set(current.memorableReasons)
        let candidateReasons = Set(candidate.memorableReasons)
        score += currentReasons.intersection(candidateReasons).count * 2

        // Close date (within 30 days)
        let days = abs(current.date.timeIntervalSince(candidate.date)) / 86_400
        if days <= 30 {
            score += 1
        }

        return score
    }

    private static func normalizedLocation(memory: Memory, album: Album) -> String? {
        let raw = memory.location ?? album.location
        return raw?
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    // MARK: - Top similar memories with fallbacks

    /// Up to 3 similar memories for `current`, using the scoring above,
    /// with fallbacks for sparse data.
    ///
    ///   1. Same album, highest score first.
    ///   2. If <3, other-album memories that share at least one tag.
    ///   3. If still <3, most recently created memories.
    ///   4. Excludes the current memory.
    static func similarMemories(
        for current: Memory,
        in currentAlbum: Album,
        allMemories: [Memory],
        allAlbums: [Album],
        limit: Int = 3
    ) -> [SimilarMemoryEntry] {
        let albumLookup = Dictionary(uniqueKeysWithValues: allAlbums.map { ($0.id, $0) })

        func score(_ memory: Memory) -> SimilarMemoryEntry? {
            guard let album = albumLookup[memory.albumId] else { return nil }
            let s = similarityScore(
                candidate: memory,
                candidateAlbum: album,
                current: current,
                currentAlbum: currentAlbum
            )
            return SimilarMemoryEntry(memory: memory, album: album, score: s)
        }

        // 1) Same album, sorted by score
        var result = allMemories
            .filter { $0.id != current.id && $0.albumId == current.albumId }
            .compactMap(score)
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }

        // 2) Fallback: other albums with at least one tag overlap
        if result.count < limit {
            let currentTags = Set(currentAlbum.tags.map { $0.lowercased() })
            let usedIds = Set(result.map { $0.memory.id } + [current.id])

            let tagOverlap = allMemories
                .filter { mem in
                    !usedIds.contains(mem.id) &&
                    mem.albumId != current.albumId &&
                    {
                        guard let album = albumLookup[mem.albumId] else { return false }
                        let candTags = Set(album.tags.map { $0.lowercased() })
                        return !currentTags.intersection(candTags).isEmpty
                    }()
                }
                .compactMap(score)
                .sorted { $0.score > $1.score }

            result.append(contentsOf: tagOverlap.prefix(limit - result.count))
        }

        // 3) Fallback: most recently created
        if result.count < limit {
            let usedIds = Set(result.map { $0.memory.id } + [current.id])
            let recent = allMemories
                .filter { !usedIds.contains($0.id) }
                .sorted { $0.createdAt > $1.createdAt }
                .compactMap(score)

            result.append(contentsOf: recent.prefix(limit - result.count))
        }

        return result
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
