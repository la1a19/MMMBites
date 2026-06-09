//
//  MemoryDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//

import SwiftUI

private struct EmojiReactionCategory: Identifiable {
    let name: String
    let icon: String
    let emojis: [String]

    var id: String { name }
}

struct MemoryDetailView: View {
    let albumTitle: String
    let album: Album?
    var onUpdate: ((Memory) -> Void)? = nil

    // Mock current user id (later: from auth)
    private let currentUserId = "jisu"

    @State private var memory: Memory
    @State private var currentPhotoIndex = 0
    @State private var reactions: [Reaction]
    @State private var heartBurst = false
    @State private var bumpedEmoji: String? = nil
    @State private var showEditSheet = false
    @State private var showEmojiPicker = false
    @State private var selectedEmojiCategory = "Smileys"

    private let emojiCategories: [EmojiReactionCategory] = [
        EmojiReactionCategory(
            name: "Smileys",
            icon: "😀",
            emojis: ["😀", "😃", "😄", "😁", "😆", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😍", "🥰", "😘", "😋", "😛", "😜", "🤪", "😎", "🤓", "🥹", "😭", "🫠", "😳", "😤", "😌", "😴", "🤯"]
        ),
        EmojiReactionCategory(
            name: "Food",
            icon: "🍽️",
            emojis: ["🍽️", "🍕", "🍔", "🍟", "🌭", "🍗", "🍖", "🍜", "🍝", "🍣", "🍙", "🍚", "🍛", "🍤", "🥟", "🥗", "🥪", "🥐", "🍞", "🧀", "🍰", "🧁", "🍦", "🍓", "🍇", "🍉", "🍌", "🍎", "☕️", "🧋", "🍵", "🌶️"]
        ),
        EmojiReactionCategory(
            name: "Mood",
            icon: "✨",
            emojis: ["✨", "🫶", "💖", "💕", "💗", "💫", "🌟", "🔥", "😍", "🥹", "😂", "😌", "🥰", "😭", "🤩", "😎"]
        ),
        EmojiReactionCategory(
            name: "Places",
            icon: "🧺",
            emojis: ["🧺", "🌳", "🌊", "🌇", "🏙️", "🏠", "🏕️", "🪴", "☀️", "🌙", "🌈", "🍃"]
        ),
        EmojiReactionCategory(
            name: "Celebration",
            icon: "🎉",
            emojis: ["🎉", "🥳", "🎂", "🎁", "🎈", "🕯️", "🍰", "✨", "🌟", "💖", "🫶"]
        )
    ]

    private var selectedEmojiCategoryItems: [String] {
        emojiCategories.first { $0.name == selectedEmojiCategory }?.emojis ?? emojiCategories[0].emojis
    }

    // Scored similar memories (computed upstream by AlbumDetailView)
    private let similarMemories: [SimilarMemoryEntry]

    init(
        memory: Memory,
        albumTitle: String,
        album: Album? = nil,
        similarMemories: [SimilarMemoryEntry] = [],
        onUpdate: ((Memory) -> Void)? = nil
    ) {
        self.albumTitle = albumTitle
        self.album = album
        self.similarMemories = similarMemories
        self.onUpdate = onUpdate
        _memory = State(initialValue: memory)
        _reactions = State(initialValue: memory.reactions)
    }

    // Group reactions by emoji to show counts (❤️ 1, 😋 2)
    private var reactionCounts: [(emoji: String, count: Int)] {
        let grouped = Dictionary(grouping: reactions, by: { $0.emoji })
        return grouped.map { (emoji: $0.key, count: $0.value.count) }
            .sorted { $0.emoji < $1.emoji }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {

                    // Photo carousel with arrows + double-tap heart
                    photoCarousel
                        .bounceOnAppear()

                    // Album + date
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(AppColor.secondary)
                            Text(albumTitle)
                                .font(AppFont.subheadline.weight(.semibold))
                                .foregroundColor(AppColor.ink)
                        }
                        .pillSurface()

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(AppColor.accent)
                            Text(memory.date, style: .date)
                                .font(AppFont.subheadline)
                                .foregroundColor(AppColor.ink)
                        }
                        .pillSurface()
                    }
                    .bounceOnAppear(delay: 0.05)

                    // Title + edit
                    HStack(alignment: .firstTextBaseline) {
                        Text(memory.title)
                            .font(.clash(34, weight: .black))
                            .foregroundColor(AppColor.ink)
                        Spacer()
                        Button {
                            Haptics.tap()
                            showEditSheet = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(AppColor.ink)
                                .padding(10)
                                .background(AppGradient.glass, in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                        .pressableScale()
                    }
                    .bounceOnAppear(delay: 0.1)

                    // Recap sentence (why this memory matters)
                    recapCard
                        .bounceOnAppear(delay: 0.11)

                    // Location
                    if let location = memory.location {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(AppColor.primary)
                            Text(location)
                                .font(AppFont.subheadline)
                                .foregroundColor(AppColor.inkMuted)
                        }
                        .bounceOnAppear(delay: 0.12)
                    }

                    // Map preview (when coordinates available)
                    if let lat = memory.latitude, let lon = memory.longitude {
                        MemoryMapPreview(
                            latitude: lat,
                            longitude: lon,
                            title: memory.location ?? memory.title
                        )
                        .bounceOnAppear(delay: 0.13)
                    }

                    // Captured by + mood
                    HStack(spacing: AppSpacing.m) {
                        AvatarView(initials: memory.capturedById ?? "?", size: 42, showRing: true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Captured by")
                                .font(AppFont.tiny)
                                .foregroundColor(AppColor.inkFaint)
                            Text(memory.capturedById ?? "Unknown")
                                .font(AppFont.subheadline.weight(.bold))
                                .foregroundColor(AppColor.ink)
                        }
                        Spacer()
                        if let mood = memory.mood {
                            moodPill(mood)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    .bounceOnAppear(delay: 0.15)

                    // People (participants)
                    if !memory.participantIds.isEmpty {
                        peopleRow
                            .bounceOnAppear(delay: 0.17)
                    }

                    // Memorable reasons
                    if !memory.memorableReasons.isEmpty {
                        memorableReasonsRow
                            .bounceOnAppear(delay: 0.18)
                    }

                    // Best bite
                    if let bite = memory.bestBite, !bite.isEmpty {
                        bestBiteCard(bite)
                            .bounceOnAppear(delay: 0.19)
                    }

                    // Note entry — always shown; placeholder when empty
                    VStack(alignment: .leading, spacing: AppSpacing.s) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.opening")
                                .foregroundColor(AppColor.accent)
                            Text("Note Entry")
                                .font(AppFont.headline)
                                .foregroundColor(AppColor.ink)
                            Spacer()
                            if memory.note == nil {
                                Button {
                                    Haptics.tap()
                                    // open editor later
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.clash(11, weight: .bold))
                                        Text("Add")
                                            .font(AppFont.tiny)
                                    }
                                    .foregroundColor(AppColor.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if let note = memory.note {
                            Text(note)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.ink)
                                .lineSpacing(4)
                        } else {
                            Text("No note yet — tap Add to write what made this moment special.")
                                .font(AppFont.body)
                                .foregroundColor(AppColor.inkFaint)
                                .italic()
                                .lineSpacing(4)
                        }
                    }
                    .glassCard()
                    .bounceOnAppear(delay: 0.2)

                    // Reactions
                    reactionsRow
                        .bounceOnAppear(delay: 0.25)

                    // Similar memories — always shown; placeholder when none
                    VStack(alignment: .leading, spacing: AppSpacing.m) {
                        HStack {
                            Text("Similar memories")
                                .font(AppFont.titleSmall)
                                .foregroundColor(AppColor.ink)
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundColor(AppColor.accent)
                        }
                        if similarMemories.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(AppColor.inkFaint)
                                Text("Similar memories will appear here as you add more.")
                                    .font(AppFont.caption)
                                    .foregroundColor(AppColor.inkFaint)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                    .strokeBorder(
                                        AppColor.inkFaint.opacity(0.35),
                                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                                    )
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.m) {
                                    ForEach(similarMemories) { entry in
                                        NavigationLink {
                                            MemoryDetailView(
                                                memory: entry.memory,
                                                albumTitle: entry.album.title
                                            )
                                        } label: {
                                            similarThumbnail(entry: entry)
                                        }
                                        .buttonStyle(.plain)
                                        .pressableScale()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppSpacing.s)
                    .bounceOnAppear(delay: 0.3)
                }
                .padding(AppSpacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.clash(13, weight: .semibold))
                    Text(albumTitle)
                        .font(AppFont.subheadline.weight(.semibold))
                }
                .foregroundColor(AppColor.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Haptics.tap()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        Haptics.tap()
                    } label: {
                        Label("Add to favourites", systemImage: "heart")
                    }
                    Button(role: .destructive) {
                        Haptics.warning()
                    } label: {
                        Label("Delete memory", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.clash(20, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddMemoryView(
                    album: album ?? Album(id: memory.albumId, title: albumTitle, ownerId: ""),
                    memoryToEdit: memory
                ) { updated in
                    withAnimation(AppAnimation.snappy) {
                        memory = updated
                        reactions = updated.reactions
                    }
                    onUpdate?(updated)
                }
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            emojiPickerSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Photo carousel

    private var photoCarousel: some View {
        ZStack {
            if photoCount == 0 {
                RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                    .fill(AppGradient.glass)
                    .frame(height: 320)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.clash(48, weight: .light))
                                .foregroundColor(AppColor.inkFaint)
                            Text("No photos yet")
                                .font(AppFont.subheadline)
                                .foregroundColor(AppColor.inkFaint)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
            } else {
                TabView(selection: $currentPhotoIndex) {
                    ForEach(0..<photoCount, id: \.self) { index in
                        photoSlide(at: index)
                            .frame(height: 320)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 10)

                // Top gradient for legibility
                LinearGradient(
                    colors: [.black.opacity(0.35), .clear],
                    startPoint: .top, endPoint: .center
                )
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                .allowsHitTesting(false)

                // Photo count chip
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.clash(10, weight: .bold))
                            Text("\(currentPhotoIndex + 1) / \(photoCount)")
                                .font(AppFont.tiny)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                        .padding(12)
                    }
                    Spacer()
                }

                // Left / right arrows
                HStack {
                    if currentPhotoIndex > 0 {
                        carouselArrow(systemName: "chevron.left") {
                            withAnimation(AppAnimation.snappy) { currentPhotoIndex -= 1 }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    Spacer()
                    if currentPhotoIndex < photoCount - 1 {
                        carouselArrow(systemName: "chevron.right") {
                            withAnimation(AppAnimation.snappy) { currentPhotoIndex += 1 }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 8)
                .animation(AppAnimation.snappy, value: currentPhotoIndex)
            }

            // Double-tap heart burst
            if heartBurst {
                Image(systemName: "heart.fill")
                    .font(.clash(96, weight: .bold))
                    .foregroundStyle(AppGradient.hero)
                    .shadow(color: .black.opacity(0.25), radius: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            triggerDoubleTapLove()
        }
    }

    // MARK: - Photo source

    private var photoCount: Int {
        memory.photoData.isEmpty ? memory.imageURLs.count : memory.photoData.count
    }

    @ViewBuilder
    private func photoSlide(at index: Int) -> some View {
        if !memory.photoData.isEmpty,
           index < memory.photoData.count,
           let img = UIImage(data: memory.photoData[index]) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if index < memory.imageURLs.count {
            AsyncImage(url: URL(string: memory.imageURLs[index])) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(AppColor.bgMint).shimmering()
            }
        } else {
            Rectangle().fill(AppColor.bgMint)
        }
    }

    // MARK: - Recap sentence (lead paragraph)

    private var recapCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.clash(14, weight: .semibold))
                .foregroundStyle(AppGradient.hero)
            Text(memory.recapSentence)
                .font(.clash(15, weight: .regular))
                .italic()
                .foregroundColor(AppColor.ink)
                .lineSpacing(3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppGradient.glass,
                    in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Mood pill

    private func moodPill(_ mood: MemoryMood) -> some View {
        HStack(spacing: 6) {
            Text(mood.emoji)
                .font(.system(size: 14))
            Text(mood.label)
                .font(.clash(12, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(AppColor.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(AppColor.accent.opacity(0.22)))
        .overlay(Capsule().stroke(AppColor.accent.opacity(0.5), lineWidth: 1))
    }

    // MARK: - People row

    private var peopleRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PEOPLE")
                .font(.clash(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.m) {
                    ForEach(memory.participantIds, id: \.self) { person in
                        VStack(spacing: 6) {
                            AvatarView(initials: person, size: 52, showRing: true)
                            Text(person)
                                .font(.clash(11, weight: .medium))
                                .foregroundColor(AppColor.ink)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Memorable reasons

    private var memorableReasonsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT MADE IT MEMORABLE")
                .font(.clash(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 4)

            FlowLayout(spacing: 8) {
                ForEach(memory.memorableReasons) { reason in
                    HStack(spacing: 6) {
                        Image(systemName: reason.icon)
                            .font(.clash(11, weight: .semibold))
                        Text(reason.label)
                            .font(.clash(13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppColor.secondary))
                    .shadow(color: AppColor.secondary.opacity(0.35), radius: 5, y: 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Best bite

    private func bestBiteCard(_ bite: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(AppColor.primary.opacity(0.2))
                    .frame(width: 42, height: 42)
                Image(systemName: "fork.knife")
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(AppColor.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("THE BEST BITE")
                    .font(.clash(11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(AppColor.inkMuted)
                Text(bite)
                    .font(.clash(17, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    // MARK: - Similar thumbnail

    private func similarThumbnail(entry: SimilarMemoryEntry) -> some View {
        VStack(spacing: 6) {
            ZStack {
                MemoryPhotoThumbnail(
                    photoData: entry.memory.photoData,
                    imageURLs: entry.memory.imageURLs,
                    width: 84,
                    height: 84,
                    placeholderSystemImage: "photo"
                )
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

            Text(entry.memory.title)
                .font(AppFont.tiny)
                .foregroundColor(AppColor.inkMuted)
                .lineLimit(1)
                .frame(width: 84)
        }
    }

    private func carouselArrow(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.clash(14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reactions

    private var reactionsRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Reactions")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 4)

            FlowLayout(spacing: 10) {
                ForEach(reactionCounts, id: \.emoji) { item in
                    Button {
                        addReaction(item.emoji)
                    } label: {
                        reactionChip(emoji: item.emoji, count: item.count)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    Haptics.tap()
                    showEmojiPicker = true
                } label: {
                    addReactionButton
                }
                .buttonStyle(.plain)
            }
            .animation(AppAnimation.snappy, value: reactionCounts.map(\.emoji))
        }
    }

    private func reactionChip(emoji: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.clash(18))
                .scaleEffect(bumpedEmoji == emoji ? 1.4 : 1.0)
                .animation(AppAnimation.bouncy, value: bumpedEmoji)
            Text("\(count)")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.ink)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(
                hasReacted(emoji)
                ? AppColor.secondary.opacity(0.25)
                : Color.white.opacity(0.85)
            )
        )
        .overlay(
            Capsule().stroke(
                hasReacted(emoji)
                ? AppColor.secondary.opacity(0.6)
                : Color.white.opacity(0.6),
                lineWidth: hasReacted(emoji) ? 1.5 : 1
            )
        )
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var addReactionButton: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.clash(11, weight: .bold))
            Text("Add")
                .font(AppFont.captionBold)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(AppColor.ink)
        .frame(width: 78, height: 38)
        .background(Capsule().fill(Color.white.opacity(0.85)))
        .overlay(
            Capsule().stroke(
                AppColor.primary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
            )
        )
    }

    private var emojiPickerSheet: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiCategories) { category in
                                Button {
                                    Haptics.selection()
                                    withAnimation(AppAnimation.snappy) {
                                        selectedEmojiCategory = category.name
                                    }
                                } label: {
                                    Text(category.icon)
                                        .font(.clash(22))
                                        .frame(width: 42, height: 36)
                                        .background(
                                            Capsule().fill(
                                                selectedEmojiCategory == category.name
                                                ? AppColor.secondary.opacity(0.25)
                                                : Color.white.opacity(0.82)
                                            )
                                        )
                                        .overlay(
                                            Capsule().stroke(
                                                selectedEmojiCategory == category.name
                                                ? AppColor.secondary.opacity(0.65)
                                                : Color.white.opacity(0.6),
                                                lineWidth: selectedEmojiCategory == category.name ? 1.5 : 1
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }

                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(42), spacing: 8), count: 6),
                            spacing: 10
                        ) {
                            ForEach(selectedEmojiCategoryItems, id: \.self) { emoji in
                                Button {
                                    addReaction(emoji)
                                    showEmojiPicker = false
                                } label: {
                                    Text(emoji)
                                        .font(.clash(24))
                                        .frame(width: 42, height: 42)
                                        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .pressableScale(0.92)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
                .padding(.top, AppSpacing.m)
            }
            .navigationTitle("Add Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.tap()
                        showEmojiPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Reaction logic

    // Has the current user reacted with this emoji?
    private func hasReacted(_ emoji: String) -> Bool {
        reactions.contains { $0.userId == currentUserId && $0.emoji == emoji }
    }

    // Adds a reaction entry so repeated taps increase that emoji's count.
    private func addReaction(_ emoji: String) {
        Haptics.selection()
        bumpedEmoji = emoji
        withAnimation(AppAnimation.bouncy) {
            reactions.append(Reaction(userId: currentUserId, emoji: emoji))
            memory.reactions = reactions
        }
        onUpdate?(memory)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            bumpedEmoji = nil
        }
        // TODO: persist this change to Firestore via a ViewModel
    }

    private func triggerDoubleTapLove() {
        Haptics.success()
        addReaction("❤️")
        withAnimation(AppAnimation.bouncy) { heartBurst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(AppAnimation.smooth) { heartBurst = false }
        }
    }
}

#Preview {
    NavigationStack {
        MemoryDetailView(
            memory: Memory(
                albumId: "1",
                title: "Picnic Fun",
                note: "We had so much fun at the park today, I went with my super amazing friends and we ate super good food. Everyone brought their own food, I brought fairy bread and everyone said it was super good.",
                imageURLs: [],
                location: "Centennial Park, Sydney",
                capturedById: "Jisu",
                reactions: [
                    Reaction(userId: "jisu", emoji: "❤️"),
                    Reaction(userId: "ada", emoji: "😋"),
                    Reaction(userId: "tin", emoji: "😋")
                ],
                date: Date()
            ),
            albumTitle: "Park",
            similarMemories: {
                let mockAlbum = Album(id: "1", title: "Park", ownerId: "jisu",
                                      tags: ["Nature"], location: "Centennial Park, Sydney")
                return [
                    SimilarMemoryEntry(memory: Memory(albumId: "1", title: "Sim 1"),
                                       album: mockAlbum, score: 8),
                    SimilarMemoryEntry(memory: Memory(albumId: "1", title: "Sim 2"),
                                       album: mockAlbum, score: 6),
                    SimilarMemoryEntry(memory: Memory(albumId: "1", title: "Sim 3"),
                                       album: mockAlbum, score: 5)
                ]
            }()
        )
    }
}
