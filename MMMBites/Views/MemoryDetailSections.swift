//
//  MemoryDetailSections.swift
//  MMMBites
//
//  Smaller content sections for MemoryDetailView.
//

import SwiftUI

struct MemoryHeader: View {
    let memory: Memory
    @Binding var currentPhotoIndex: Int
    let heartBurst: Bool
    let onDoubleTapLove: () -> Void

    private var photoCount: Int {
        memory.photoData.isEmpty ? memory.imageURLs.count : memory.photoData.count
    }

    var body: some View {
        photoCarousel
    }

    private var photoCarousel: some View {
        ZStack {
            if photoCount == 0 {
                RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                    .fill(AppGradient.glass)
                    .frame(height: 320)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.clash(48, weight: .light))
                            Text("No photos yet")
                                .font(AppFont.subheadline)
                        }
                        .foregroundColor(AppColor.inkFaint)
                    }
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

                LinearGradient(
                    colors: [.black.opacity(0.35), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                .allowsHitTesting(false)

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

            if heartBurst {
                Image(systemName: "heart.fill")
                    .font(.clash(96, weight: .bold))
                    .foregroundStyle(AppGradient.heroText)
                    .shadow(color: AppColor.primary.opacity(0.3), radius: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onDoubleTapLove)
    }

    @ViewBuilder
    private func photoSlide(at index: Int) -> some View {
        if !memory.photoData.isEmpty,
           index < memory.photoData.count,
           let image = UIImage(data: memory.photoData[index]) {
            Image(uiImage: image)
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
}

struct MemoryTitleSection: View {
    let memory: Memory
    let albumTitle: String
    let isFavourite: Bool
    let favouriteBurst: Bool
    let canEditMemory: Bool
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.clash(11, weight: .semibold))
                    .foregroundColor(AppColor.secondary)
                Text(albumTitle)
                Text("·")
                    .foregroundColor(AppColor.inkFaint)
                Image(systemName: "calendar")
                    .font(.clash(11, weight: .semibold))
                    .foregroundColor(AppColor.accent)
                Text(memory.date, style: .date)
            }
            .font(AppFont.caption)
            .foregroundColor(AppColor.inkMuted)

            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(memory.title)
                        .font(.clash(34, weight: .black))
                        .foregroundColor(AppColor.ink)
                    if isFavourite {
                        Image(systemName: "heart.fill")
                            .font(.clash(20, weight: .semibold))
                            .foregroundStyle(AppGradient.heroText)
                            .scaleEffect(favouriteBurst ? 1.35 : 1)
                            .animation(AppAnimation.bouncy, value: favouriteBurst)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Spacer()
                if canEditMemory {
                    Button(action: onEdit) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppColor.ink)
                            .padding(10)
                            .glassCircleSurface()
                    }
                    .buttonStyle(.plain)
                    .pressableScale()
                }
            }
        }
    }
}

struct MemoryMoodCard: View {
    let memory: Memory

    var body: some View {
        if let mood = memory.mood {
            HStack(spacing: 10) {
                Text(mood.emoji)
                    .font(.system(size: 22))
                Text("HOW IT FELT")
                    .font(.clash(9, weight: .semibold))
                    .tracking(1.1)
                    .foregroundColor(AppColor.inkMuted)
                Text(mood.label)
                    .font(.clash(15, weight: .bold))
                    .foregroundStyle(AppGradient.heroText)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        }
    }
}

struct MemoryLocationRow: View {
    let memory: Memory

    var body: some View {
        if let location = memory.location, !location.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(AppColor.primary)
                    Text(location)
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundColor(AppColor.ink)
                }
                if let lat = memory.latitude, let lon = memory.longitude {
                    MemoryMapPreview(
                        latitude: lat,
                        longitude: lon,
                        title: location
                    )
                }
            }
        }
    }
}

struct MemoryCapturedByRow: View {
    let capturedByName: String
    let capturedByAvatar: Image?

    var body: some View {
        HStack(spacing: 8) {
            AvatarView(
                avatar: capturedByAvatar,
                initials: capturedByName,
                size: 22
            )
            HStack(spacing: 0) {
                Text("Captured by ")
                    .foregroundColor(AppColor.inkFaint)
                Text(capturedByName)
                    .foregroundColor(AppColor.inkMuted)
                    .fontWeight(.semibold)
            }
            .font(AppFont.caption)
        }
    }
}

struct MemoryNoteCard: View {
    let memory: Memory
    let canEditMemory: Bool
    let onEditNote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .foregroundColor(AppColor.accent)
                Text("Note")
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.ink)
                Spacer()
                if canEditMemory {
                    Button(action: onEditNote) {
                        HStack(spacing: 4) {
                            Image(systemName: memory.note == nil ? "plus" : "square.and.pencil")
                                .font(.clash(11, weight: .bold))
                            Text(memory.note == nil ? "Add" : "Edit")
                                .font(AppFont.tiny)
                        }
                        .foregroundColor(AppColor.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(noteText)
                .font(AppFont.body)
                .foregroundColor(memory.note == nil ? AppColor.inkFaint : AppColor.ink)
                .italic(memory.note == nil)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    if canEditMemory { onEditNote() }
                }
        }
        .glassCard()
    }

    private var noteText: String {
        if let note = memory.note, !note.isEmpty {
            return note
        }
        return canEditMemory
        ? "No note yet - tap Add to write what made this moment special."
        : "No note yet."
    }
}

struct MemoryExtrasCard: View {
    let memory: Memory
    let currentUserID: String?
    let friendName: (String) -> String
    let friendAvatarImage: (String) -> Image?
    let canChooseFriendTags: Bool
    let onAddFriendTag: (String) -> Void
    let onDeleteFriendTag: (FriendMemorableTag) -> Void

    @State private var customFriendTag: String = ""
    @FocusState private var isCustomTagFocused: Bool

    private var hasBestBite: Bool {
        !(memory.bestBite ?? "").isEmpty
    }

    private var hasMemorable: Bool {
        !memory.memorableTags.isEmpty || !friendMemorableTags.isEmpty || canChooseFriendTags
    }

    private var hasPeople: Bool {
        !memory.participantIds.isEmpty
    }

    private var friendMemorableTags: [FriendMemorableTag] {
        memory.friendMemorableTags ?? []
    }

    var body: some View {
        if hasBestBite || hasMemorable || hasPeople {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                if let bite = memory.bestBite, !bite.isEmpty {
                    bestBiteBlock(bite)
                }

                if hasMemorable {
                    if hasBestBite { MemoryCardDivider() }
                    memorableTagsBlock
                }

                if hasPeople {
                    if hasBestBite || hasMemorable { MemoryCardDivider() }
                    peopleBlock
                }
            }
            .glassCard()
        }
    }

    private func bestBiteBlock(_ bite: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(AppColor.primary.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "fork.knife")
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(AppColor.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("THE BEST BITE")
                    .font(.clash(10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(AppColor.inkMuted)
                Text(bite)
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
    }

    private var memorableTagsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT MADE IT MEMORABLE")
                .font(.clash(10, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)

            if !memory.memorableTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(memory.memorableTags, id: \.self) { tag in
                        creatorTagChip(tag)
                    }
                }
            }

            if !friendMemorableTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(friendMemorableTags.sorted { $0.createdAt > $1.createdAt }) { friendTag in
                        friendTagChip(friendTag)
                    }
                }
            }

            if canChooseFriendTags {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD YOUR REASONS")
                        .font(.clash(10, weight: .semibold))
                        .tracking(1.1)
                        .foregroundColor(AppColor.inkFaint)

                    customFriendTagField
                }
                .padding(.top, 2)
            }
        }
    }

    private func creatorTagChip(_ tag: String) -> some View {
        Text(tag)
            .font(.clash(12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppColor.tag(tag)))
            .shadow(color: AppColor.tag(tag).opacity(0.35), radius: 4, y: 2)
    }

    private func friendTagChip(_ friendTag: FriendMemorableTag) -> some View {
        let canDelete = friendTag.userId == currentUserID

        return HStack(spacing: 5) {
            Text(friendTag.tag)
                .font(.clash(12, weight: .semibold))

            if canDelete {
                Button {
                    Haptics.warning()
                    onDeleteFriendTag(friendTag)
                } label: {
                    Image(systemName: "xmark")
                        .font(.clash(9, weight: .bold))
                        .foregroundColor(AppColor.secondary)
                        .frame(width: 14, height: 14)
                        .background(AppColor.secondary.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundColor(AppColor.secondary)
        .padding(.horizontal, canDelete ? 8 : 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(AppColor.secondary.opacity(0.10)))
        .overlay(Capsule().stroke(AppColor.secondary.opacity(0.45), lineWidth: 1.2))
    }

    private var customFriendTagField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.clash(11, weight: .bold))
                .foregroundColor(AppColor.secondary)

            TextField("Add memorable reasons", text: $customFriendTag)
                .font(AppFont.caption)
                .foregroundColor(AppColor.ink)
                .focused($isCustomTagFocused)
                .submitLabel(.done)
                .onSubmit(addCustomFriendTag)

            Button(action: addCustomFriendTag) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.clash(20, weight: .bold))
                    .foregroundColor(canSubmitCustomFriendTag ? AppColor.secondary : AppColor.inkFaint)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmitCustomFriendTag)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
        .background(AppColor.secondary.opacity(0.08), in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(AppColor.secondary.opacity(0.35), lineWidth: 1.1))
    }

    private var canSubmitCustomFriendTag: Bool {
        !customFriendTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addCustomFriendTag() {
        let trimmed = customFriendTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddFriendTag(trimmed)
        customFriendTag = ""
        isCustomTagFocused = false
    }

    private var peopleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PEOPLE")
                .font(.clash(10, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.m) {
                    ForEach(memory.participantIds, id: \.self) { personID in
                        VStack(spacing: 6) {
                            AvatarView(
                                avatar: friendAvatarImage(personID),
                                initials: friendName(personID),
                                size: 46,
                                showRing: true
                            )
                            Text(friendName(personID))
                                .font(.clash(11, weight: .medium))
                                .foregroundColor(AppColor.ink)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

struct MemoryReactionsSection: View {
    let reactionCounts: [(emoji: String, count: Int)]
    let bumpedEmoji: String?
    let hasReacted: (String) -> Bool
    let onAddReaction: (String) -> Void
    let onOpenPicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Reactions")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 4)

            FlowLayout(spacing: 10) {
                ForEach(reactionCounts, id: \.emoji) { item in
                    Button {
                        onAddReaction(item.emoji)
                    } label: {
                        reactionChip(emoji: item.emoji, count: item.count)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Button(action: onOpenPicker) {
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
                : AppColor.surface.opacity(0.85)
            )
        )
        .overlay(
            Capsule().stroke(
                hasReacted(emoji)
                ? AppColor.secondary.opacity(0.6)
                : AppColor.surfaceGlass.opacity(0.86),
                lineWidth: hasReacted(emoji) ? 1.5 : 1
            )
        )
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
        .background(Capsule().fill(AppColor.surface.opacity(0.85)))
        .overlay(
            Capsule().stroke(
                AppColor.primary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
            )
        )
    }
}


struct MemorySimilarSection: View {
    let similarMemories: [SimilarMemoryEntry]

    var body: some View {
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
                emptyState
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
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "wand.and.stars")
                .foregroundColor(AppColor.inkFaint)
            Text("Memories with matching moods or tags will appear here.")
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
    }

    private func similarThumbnail(entry: SimilarMemoryEntry) -> some View {
        VStack(spacing: 6) {
            MemoryPhotoThumbnail(
                photoData: entry.memory.photoData,
                imageURLs: entry.memory.imageURLs,
                width: 84,
                height: 84,
                placeholderSystemImage: "photo"
            )
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

            Text(entry.memory.title)
                .font(AppFont.tiny)
                .foregroundColor(AppColor.inkMuted)
                .lineLimit(1)
                .frame(width: 84)
        }
    }
}

private struct MemoryCardDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColor.inkFaint.opacity(0.15))
            .frame(height: 1)
    }
}
