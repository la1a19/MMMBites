//
//  MemorySearchView.swift
//  MMMBites
//
//  Cross-album memory search and filtering by mood / memorable tags / text.
//

import SwiftUI

struct MemorySearchView: View {
    let memories: [Memory]
    let albums: [Album]

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var selectedMoods: Set<MemoryMood> = []
    @State private var selectedTags: Set<String> = []

    private var availableTags: [String] {
        var counts: [String: Int] = [:]
        for memory in memories {
            for tag in memory.memorableTags {
                let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                counts[trimmed.lowercased(), default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.map { $0.key.capitalized }
    }

    private var filteredMemories: [Memory] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return memories.filter { memory in
            if !selectedMoods.isEmpty {
                guard let mood = memory.mood, selectedMoods.contains(mood) else { return false }
            }
            if !selectedTags.isEmpty {
                let memTags = Set(memory.memorableTags.map { $0.lowercased() })
                let selected = Set(selectedTags.map { $0.lowercased() })
                guard !memTags.isDisjoint(with: selected) else { return false }
            }
            if !trimmedQuery.isEmpty {
                let haystack = [
                    memory.title,
                    memory.bestBite ?? "",
                    memory.note ?? "",
                    memory.location ?? "",
                    memory.memorableTags.joined(separator: " ")
                ].joined(separator: " ").lowercased()
                guard haystack.contains(trimmedQuery) else { return false }
            }
            return true
        }
        .sorted { $0.date > $1.date }
    }

    private var hasActiveFilters: Bool {
        !query.isEmpty || !selectedMoods.isEmpty || !selectedTags.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        searchBar
                        moodFilterSection
                        if !availableTags.isEmpty {
                            tagFilterSection
                        }

                        resultsSection
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if hasActiveFilters {
                        Button {
                            Haptics.tap()
                            withAnimation(AppAnimation.snappy) {
                                query = ""
                                selectedMoods = []
                                selectedTags = []
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.clash(13, weight: .bold))
                                .foregroundColor(AppColor.ink)
                                .frame(width: 32, height: 32)
                                .glassCircleSurface()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.clash(13, weight: .bold))
                            .foregroundColor(AppColor.ink)
                            .frame(width: 32, height: 32)
                            .glassCircleSurface()
                    }
                }
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColor.inkFaint)
            TextField("Search bites, places, notes...", text: $query)
                .font(AppFont.body)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button {
                    query = ""
                    Haptics.tap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.inkFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9), in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
    }

    // MARK: - Mood filter

    private var moodFilterSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            sectionLabel("MOOD")
            FlowLayout(spacing: 6) {
                ForEach(MemoryMood.allCases) { mood in
                    moodChip(mood)
                }
            }
        }
    }

    private func moodChip(_ mood: MemoryMood) -> some View {
        let selected = selectedMoods.contains(mood)
        return Button {
            Haptics.selection()
            withAnimation(AppAnimation.snappy) {
                if selected { selectedMoods.remove(mood) } else { selectedMoods.insert(mood) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(mood.emoji).font(.system(size: selected ? 14 : 13))
                Text(mood.label)
                    .font(.clash(11, weight: selected ? .bold : .semibold))
            }
            .foregroundColor(selected ? .white : AppColor.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? AppGradient.hero : AppGradient.glass)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(selected ? 0.85 : 0.6), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tag filter

    private var tagFilterSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            sectionLabel("MEMORABLE FOR")
            FlowLayout(spacing: 6) {
                ForEach(availableTags, id: \.self) { tag in
                    tagChip(tag)
                }
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        let selected = selectedTags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
        return Button {
            Haptics.selection()
            withAnimation(AppAnimation.snappy) {
                if selected {
                    selectedTags = selectedTags.filter { $0.caseInsensitiveCompare(tag) != .orderedSame }
                } else {
                    selectedTags.insert(tag)
                }
            }
        } label: {
            Text(tag)
                .font(.clash(11, weight: selected ? .bold : .semibold))
                .foregroundColor(selected ? .white : AppColor.ink)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? AppColor.tag(tag) : Color.white.opacity(0.82))
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack {
                sectionLabel(resultsHeaderText)
                Spacer()
            }

            if filteredMemories.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: AppSpacing.s) {
                    ForEach(filteredMemories) { memory in
                        resultRow(memory)
                    }
                }
            }
        }
    }

    private var resultsHeaderText: String {
        if !hasActiveFilters {
            return "ALL MEMORIES · \(filteredMemories.count)"
        }
        return "\(filteredMemories.count) \(filteredMemories.count == 1 ? "RESULT" : "RESULTS")"
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.s) {
            Image(systemName: "magnifyingglass")
                .font(.clash(28, weight: .light))
                .foregroundColor(AppColor.inkFaint)
            Text("Nothing matches")
                .font(AppFont.subheadline)
                .foregroundColor(AppColor.inkMuted)
            Text("Try a different mood, tag, or word.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private func resultRow(_ memory: Memory) -> some View {
        let parentAlbum = album(forMemory: memory)
        return NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: parentAlbum?.title ?? "Memory",
                album: parentAlbum
            )
        } label: {
            HStack(spacing: AppSpacing.m) {
                MemoryPhotoThumbnail(
                    photoData: memory.photoData,
                    imageURLs: memory.imageURLs,
                    width: 56,
                    height: 56,
                    isCircle: false
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if let mood = memory.mood {
                            Text(mood.emoji).font(.system(size: 12))
                        }
                        Text(memory.title)
                            .font(.clash(15, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                            .lineLimit(1)
                    }
                    Text(subtitleText(for: memory))
                        .font(.clash(11, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.clash(11, weight: .bold))
                    .foregroundColor(AppColor.inkFaint)
            }
            .padding(AppSpacing.m)
            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.clash(11, weight: .semibold))
            .tracking(1.2)
            .foregroundColor(AppColor.inkMuted)
            .padding(.leading, 4)
    }

    private func album(forMemory memory: Memory) -> Album? {
        albums.first { $0.id == memory.albumId }
    }

    private func subtitleText(for memory: Memory) -> String {
        let date = memory.date.formatted(date: .abbreviated, time: .omitted)
        if let location = memory.location, !location.isEmpty {
            return "\(date) · \(location)"
        }
        return date
    }
}
