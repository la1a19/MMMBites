//
//  AlbumDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//

import SwiftUI

struct AlbumDetailView: View {
    @State private var album: Album
    var onMemoriesChange: (([Memory]) -> Void)?
    var onAlbumUpdate: ((Album) -> Void)?

    @State private var searchText = ""
    @State private var memories: [Memory]
    @State private var showEditAlbum = false

    init(
        album: Album,
        initialMemories: [Memory]? = nil,
        onMemoriesChange: (([Memory]) -> Void)? = nil,
        onAlbumUpdate: ((Album) -> Void)? = nil
    ) {
        _album = State(initialValue: album)
        self.onMemoriesChange = onMemoriesChange
        self.onAlbumUpdate = onAlbumUpdate
        // Pull from the shared mock store so cross-album similarity works.
        // Fallback to per-album mock memories if the album isn't in the store yet.
        let stored = initialMemories ?? MockData.memories(forAlbumId: album.id)
        if stored.isEmpty {
            let isMockAlbum = MockData.album(id: album.id) != nil
            _memories = State(initialValue: isMockAlbum ? Self.makeMockMemories(forAlbumId: album.id) : [])
        } else {
            _memories = State(initialValue: stored)
        }
    }

    // Legacy mock memories — only used if the album isn't in MockData (e.g. brand new albums).
    private static func makeMockMemories(forAlbumId albumId: String) -> [Memory] {
        [
            Memory(
                albumId: albumId,
                title: "Picnic Fun",
                note: "We had so much fun at the park today, I went with my super amazing friends and we ate super good food. Everyone brought their own food, I brought fairy bread and everyone said it was super good.",
                location: "Centennial Park, Sydney",
                capturedById: "Jisu",
                reactions: [
                    Reaction(userId: "jisu", emoji: "❤️"),
                    Reaction(userId: "ada",  emoji: "😋"),
                    Reaction(userId: "tin",  emoji: "😋")
                ],
                mood: .fun,
                bestBite: "Fairy bread, no question",
                memorableReasons: [.friends, .food, .atmosphere],
                participantIds: ["Judy", "Mira", "Alex"]
            ),
            Memory(
                albumId: albumId,
                title: "Sandwiches",
                note: "Ham and cheese, the classic. Mira packed extras for everyone — way too generous.",
                location: "Centennial Park, Sydney",
                capturedById: "Mira",
                reactions: [Reaction(userId: "jisu", emoji: "👍")],
                mood: .chill,
                bestBite: "Mira's leftover sandwich corners",
                memorableReasons: [.food, .friends],
                participantIds: ["Mira"]
            ),
            Memory(
                albumId: albumId,
                title: "Park fun",
                note: "Frisbee, sunshine, and the world's slowest jog. Best Sunday in a while.",
                location: "Centennial Park, Sydney",
                capturedById: "Alex",
                reactions: [Reaction(userId: "ada", emoji: "🔥")],
                mood: .fun,
                memorableReasons: [.atmosphere, .friends],
                participantIds: ["Alex", "Mira"]
            ),
            Memory(
                albumId: albumId,
                title: "Outdoors",
                location: "Centennial Park, Sydney",
                capturedById: "Sam",
                mood: .chill,
                memorableReasons: [.place],
                participantIds: ["Sam"]
            ),
            Memory(
                albumId: albumId,
                title: "Snacks",
                note: "Chips, fruit, more chips. A balanced meal.",
                capturedById: "Jisu",
                reactions: [Reaction(userId: "lila", emoji: "😂")],
                mood: .comfort,
                bestBite: "Salt-and-vinegar chips",
                memorableReasons: [.food],
                participantIds: ["Lila"]
            ),
            Memory(
                albumId: albumId,
                title: "Desserts",
                note: "Fairy bread won. As it always does.",
                capturedById: "Lila",
                reactions: [
                    Reaction(userId: "jisu", emoji: "❤️"),
                    Reaction(userId: "ada",  emoji: "❤️")
                ],
                mood: .special,
                bestBite: "Fairy bread (again)",
                memorableReasons: [.food, .conversation],
                participantIds: ["Lila", "Ada"]
            )
        ]
    }

    // Full corpus used for similarity scoring (this album + everything from MockData).
    // De-duplicates on id so the current album's memories aren't counted twice.
    private var allAlbums: [Album] {
        var byId: [String: Album] = [:]
        byId[album.id] = album
        for a in MockData.allAlbums where byId[a.id] == nil {
            byId[a.id] = a
        }
        return Array(byId.values)
    }

    private var allMemories: [Memory] {
        var byId: [String: Memory] = [:]
        for m in memories { byId[m.id] = m }
        for m in MockData.memories(excludingAlbumId: album.id) where byId[m.id] == nil {
            byId[m.id] = m
        }
        return Array(byId.values)
    }

    /// Up to 3 scored similar memories for `memory`, with fallbacks.
    private func similarMemories(for memory: Memory) -> [SimilarMemoryEntry] {
        MemorySimilarity.similarMemories(
            for: memory,
            in: album,
            allMemories: allMemories,
            allAlbums: allAlbums
        )
    }

    // Memories filtered by the search text
    private var filteredMemories: [Memory] {
        if searchText.isEmpty {
            return memories
        }
        return memories.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var totalReactionCount: Int {
        memories.reduce(0) { $0 + $1.reactions.count }
    }

    private var participantCount: Int {
        Set(memories.flatMap(\.participantIds)).count
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    // Title + location
                    VStack(alignment: .leading, spacing: AppSpacing.s) {
                        Text(album.title)
                            .font(AppFont.displayLarge)
                            .foregroundStyle(AppGradient.hero)

                        if let location = album.location {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(AppColor.primary)
                                Text(location)
                                    .font(AppFont.subheadline)
                                    .foregroundColor(AppColor.inkMuted)
                            }
                        }

                        if !album.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(album.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(AppFont.captionBold)
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(AppColor.tag(tag)))
                                            .shadow(color: AppColor.tag(tag).opacity(0.4), radius: 4, y: 2)
                                    }
                                }
                            }
                        }
                    }
                    .bounceOnAppear()

                    // Participants + Add Memory
                    HStack {
                        // Participant avatars (placeholder)
                        HStack(spacing: -10) {
                            ForEach(0..<3, id: \.self) { _ in
                                AvatarView(size: 34, showRing: true)
                            }
                            Text("+3")
                                .font(AppFont.captionBold)
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(AppColor.secondary))
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }

                        Spacer()

                        // Start a Meal Memory -> AddMemoryView
                        NavigationLink {
                            AddMemoryView(album: album) { newMemory in
                                withAnimation(AppAnimation.snappy) {
                                    memories.insert(newMemory, at: 0)
                                }
                                onMemoriesChange?(memories)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "fork.knife")
                                    .font(.clash(13, weight: .bold))
                                Text("Start a Meal Memory")
                                    .font(AppFont.subheadline.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(AppGradient.hero))
                            .shadow(color: AppColor.primary.opacity(0.35), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .pressableScale()
                    }
                    .bounceOnAppear(delay: 0.05)

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColor.inkFaint)
                        TextField("Search memories", text: $searchText)
                            .font(AppFont.body)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                Haptics.tap()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColor.inkFaint)
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.9), in: Capsule(style: .continuous))
                    .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                    .animation(AppAnimation.snappy, value: searchText)
                    .bounceOnAppear(delay: 0.1)

                    // Summary chip
                    HStack(spacing: AppSpacing.s) {
                        summaryChip(icon: "photo.stack.fill", title: "\(memories.count)", subtitle: "memories")
                        summaryChip(icon: "heart.fill", title: "\(totalReactionCount)", subtitle: "reactions", tint: AppColor.primary)
                        summaryChip(icon: "person.2.fill", title: "\(participantCount)", subtitle: "people", tint: AppColor.secondary)
                    }
                    .bounceOnAppear(delay: 0.12)

                    // Memories grid (2 columns)
                    if filteredMemories.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xl) {
                            ForEach(Array(filteredMemories.enumerated()), id: \.element.id) { index, memory in
                                memoryBubble(memory)
                                    .bounceOnAppear(delay: 0.15 + Double(index) * 0.04)
                            }
                        }
                        .padding(.top, AppSpacing.s)
                    }
                }
                .padding(AppSpacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showEditAlbum = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.clash(16, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                        .frame(width: 34, height: 34)
                        .background(AppGradient.glass, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showEditAlbum) {
            NavigationStack {
                AddAlbumView(albumToEdit: album) { updatedAlbum in
                    withAnimation(AppAnimation.snappy) {
                        album = updatedAlbum
                    }
                    onAlbumUpdate?(updatedAlbum)
                }
            }
        }
    }

    // MARK: - Summary chip

    private func summaryChip(icon: String, title: String, subtitle: String, tint: Color = AppColor.accent) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.clash(14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.18)))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(AppFont.captionBold)
                    .foregroundColor(AppColor.ink)
                Text(subtitle)
                    .font(AppFont.tiny)
                    .foregroundColor(AppColor.inkFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    // MARK: - Memory bubble

    private func memoryBubble(_ memory: Memory) -> some View {
        NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: album.title,
                album: album,
                similarMemories: similarMemories(for: memory),
                onUpdate: { updated in
                    if let idx = memories.firstIndex(where: { $0.id == updated.id }) {
                        memories[idx] = updated
                        onMemoriesChange?(memories)
                    }
                }
            )
        } label: {
            VStack(spacing: AppSpacing.s) {
                ZStack {
                    Circle()
                        .fill(AppGradient.hero)
                        .frame(width: 158, height: 158)
                        .blur(radius: 14)
                        .opacity(0.3)

                    MemoryPhotoThumbnail(
                        photoData: memory.photoData,
                        imageURLs: memory.imageURLs,
                        width: 150,
                        height: 150
                    )
                }
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 6)

                Text(memory.title)
                    .font(AppFont.subheadline.weight(.semibold))
                    .foregroundColor(AppColor.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule(style: .continuous))
                    .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
        }
        .buttonStyle(.plain)
        .pressableScale()
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "photo.stack")
                .font(.clash(44, weight: .light))
                .foregroundColor(AppColor.inkFaint)
                .padding(.top, 40)
            Text("No memories found")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text("Try a different search or add your first memory.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(album: Album(
            title: "PARK",
            ownerId: "jisu",
            tags: ["Tree", "nature", "Picnic"],
            location: "Centennial Park, Sydney",
            date: Date()
        ))
    }
}
