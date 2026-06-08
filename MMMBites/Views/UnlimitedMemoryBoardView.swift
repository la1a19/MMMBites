//
//  UnlimitedMemoryBoardView.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//

import SwiftUI

struct UnlimitedMemoryBoardView: View {
    let albums: [Album]
    @Binding var albumMemories: [String: [Memory]]
    @Binding var showUnlimitedBoard: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var boardOffset: CGSize = .zero
    @State private var lastBoardOffset: CGSize = .zero
    @State private var hasSetInitialPosition = false
    
    @State private var returnButtonDragY: CGFloat = 0
    @State private var selectedBoardItem: BoardMemoryItem?
    
    @State private var boardLayoutSeed = UUID().uuidString
    @State private var memoryActivities: [String: MemoryActivity] = [:]
    @State private var activityAnimationOn = false
    
    @State private var seenActivityMemoryIds: Set<String> = []
    
    @State private var memoryActivityService = CombinedMemoryActivityService()
    
    private let boardSize = CGSize(width: 2600, height: 2600)
    private let panSensitivity: CGFloat = 0.55
    private let renderMargin: CGFloat = 420

    private var allMemories: [Memory] {
        albums.flatMap { album in
            albumMemories[album.id] ?? []
        }
    }

    private var boardItems: [BoardMemoryItem] {
        let pairs: [(album: Album, memory: Memory)] = albums.flatMap { album in
            let memories = albumMemories[album.id] ?? []
            return memories.map { memory in
                (album: album, memory: memory)
            }
        }

        var placedItems: [BoardMemoryItem] = []

        for (index, pair) in pairs.enumerated() {
            let size = boardBubbleSize(for: pair.memory.id)

            let position = nonOverlappingPosition(
                for: pair.memory.id,
                index: index,
                size: size,
                placedItems: placedItems
            )

            let item = BoardMemoryItem(
                memory: pair.memory,
                album: pair.album,
                position: position,
                size: size,
                rotation: boardRotation(for: pair.memory.id)
            )

            placedItems.append(item)
        }

        return placedItems
    }
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppBackground()

                boardCanvas(viewportSize: proxy.size)
                    .clipped()

                topReturnHandle

                VStack {
                    Spacer()

                    Text("Board memories: \(allMemories.count)")
                        .font(AppFont.captionBold)
                        .foregroundColor(AppColor.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppGradient.glass, in: Capsule())
                        .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                boardLayoutSeed = UUID().uuidString
                hasSetInitialPosition = false
                setInitialPositionIfNeeded(viewportSize: proxy.size)

                Task {
                    await loadMemoryActivities()
                }
                activityAnimationOn = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(
                        .easeInOut(duration: 1.4)
                        .repeatForever(autoreverses: false)
                    ) {
                        activityAnimationOn = true
                    }
                }
            }
            .navigationDestination(item: $selectedBoardItem) { item in
                MemoryDetailView(
                    memory: item.memory,
                    albumTitle: item.album.title,
                    album: item.album,
                    similarMemories: similarMemories(for: item),
                    onUpdate: { updatedMemory in
                        updateMemory(updatedMemory, inAlbumId: item.album.id)
                    }
                )
            }
        }
    }
    private func loadMemoryActivities() async {
        var activities = await memoryActivityService.latestActivities(for: allMemories)

        for memoryId in seenActivityMemoryIds {
            activities.removeValue(forKey: memoryId)
        }

        memoryActivities = activities
    }
    
    private func markActivityAsSeen(for memoryId: String) {
        seenActivityMemoryIds.insert(memoryId)

        withAnimation(.easeInOut(duration: 0.35)) {
            memoryActivities.removeValue(forKey: memoryId)
        }
    }
    
    private func closeBoard() {
        Haptics.soft()

        withAnimation(.easeInOut(duration: 0.65)) {
            showUnlimitedBoard = false
        }
    }
    private func elasticDragOffset(_ drag: CGFloat) -> CGFloat {
        let resistance: CGFloat = 0.62
        let maxOffset: CGFloat = 110

        let resisted = drag * resistance
        return min(resisted, maxOffset)
    }

    // MARK: - Board canvas

    private func boardCanvas(viewportSize: CGSize) -> some View {
        ZStack {
            // Put the drag gesture ONLY on the empty board background.
            // This stops the board drag from blocking bubble taps.
            Color.clear
                .frame(width: viewportSize.width, height: viewportSize.height)
                .contentShape(Rectangle())
                .gesture(boardDragGesture(viewportSize: viewportSize))

            ForEach(boardItems) { item in
                let screenPoint = screenPosition(for: item)

                Button {
                    Haptics.tap()

                    markActivityAsSeen(for: item.memory.id)

                    selectedBoardItem = item
                } label: {
                    memoryBoardBubble(item)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .position(screenPoint)
            }
        }
        .frame(width: viewportSize.width, height: viewportSize.height)
    }
    
    private func screenPosition(for item: BoardMemoryItem) -> CGPoint {
        CGPoint(
            x: item.position.x + boardOffset.width,
            y: item.position.y + boardOffset.height
        )
    }

    // MARK: - Bubble

    private func memoryBoardBubble(_ item: BoardMemoryItem) -> some View {
        let activity = memoryActivities[item.memory.id]

        return VStack(spacing: 8) {
            ZStack {
                if activity != nil {
                    activityPulse(size: item.size)
                }

                Circle()
                    .fill(AppGradient.hero)
                    .frame(width: item.size + 18, height: item.size + 18)
                    .opacity(activity == nil ? 0.25 : 0.55)
                    .blur(radius: 8)

                MemoryPhotoThumbnail(
                    photoData: item.memory.photoData,
                    imageURLs: item.memory.imageURLs,
                    width: item.size,
                    height: item.size,
                    placeholderSystemImage: "photo.on.rectangle.angled"
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.95), lineWidth: 4)
                )
                .shadow(
                    color: .black.opacity(activity == nil ? 0.18 : 0.30),
                    radius: activity == nil ? 12 : 18,
                    x: 0,
                    y: activity == nil ? 7 : 10
                )

                if let activity {
                    if let emoji = activity.emoji {
                        floatingEmoji(emoji, size: item.size)
                    }

                    activityBadge(activity)
                        .offset(x: item.size * 0.34, y: -item.size * 0.42)
                }
            }

            Text(item.memory.title)
                .font(.clash(12, weight: .semibold))
                .foregroundColor(AppColor.ink)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.9), in: Capsule(style: .continuous))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                .frame(width: item.size + 50)
        }
        .rotationEffect(item.rotation)
    }
    
    private func activityPulse(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.75), lineWidth: 3)
                .frame(width: size + 22, height: size + 22)
                .scaleEffect(activityAnimationOn ? 1.45 : 1.0)
                .opacity(activityAnimationOn ? 0.0 : 0.75)

            Circle()
                .stroke(AppColor.ink.opacity(0.22), lineWidth: 4)
                .frame(width: size + 40, height: size + 40)
                .scaleEffect(activityAnimationOn ? 1.35 : 1.0)
                .opacity(activityAnimationOn ? 0.0 : 0.55)

            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: size + 58, height: size + 58)
                .scaleEffect(activityAnimationOn ? 1.25 : 1.0)
                .opacity(activityAnimationOn ? 0.0 : 0.4)
        }
    }
    
    private func floatingEmoji(_ emoji: String, size: CGFloat) -> some View {
        Text(emoji)
            .font(.system(size: 30))
            .scaleEffect(activityAnimationOn ? 1.08 : 0.92)
            .opacity(activityAnimationOn ? 0.25 : 1.0)
            .offset(
                x: activityAnimationOn ? size * 0.04 : -size * 0.02,
                y: activityAnimationOn ? -size * 0.78 : -size * 0.45
            )
    }
    
    private func activityBadge(_ activity: MemoryActivity) -> some View {
        HStack(spacing: 5) {
            Image(systemName: activity.userIconSystemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColor.ink)

            Text(activity.userDisplayName)
                .font(.clash(10, weight: .semibold))
                .foregroundColor(AppColor.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.92), in: Capsule(style: .continuous))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
    }
    // MARK: - Top return handle

    private var topReturnHandle: some View {
        VStack {
            VStack(spacing: 5) {
                Capsule()
                    .fill(AppColor.inkMuted.opacity(0.45))
                    .frame(width: 38, height: 5)

                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(.clash(12, weight: .bold))

                    Text("Back to albums")
                        .font(AppFont.captionBold)
                }
                .foregroundColor(AppColor.ink)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(AppGradient.glass, in: Capsule(style: .continuous))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
            .offset(y: elasticDragOffset(returnButtonDragY))
            .scaleEffect(1 + min(returnButtonDragY / 900, 0.08))
            .contentShape(Rectangle())
            .onTapGesture {
                closeBoard()
            }
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        if value.translation.height > 0 {
                            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.68)) {
                                returnButtonDragY = value.translation.height
                            }
                        }

                        if value.translation.height > 75 {
                            closeBoard()
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                            returnButtonDragY = 0
                        }
                    }
            )
            .padding(.top, 80)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .zIndex(999)
    }
    // MARK: - Drag movement

    private func boardDragGesture(viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let nextOffset = CGSize(
                    width: lastBoardOffset.width + value.translation.width * panSensitivity,
                    height: lastBoardOffset.height + value.translation.height * panSensitivity
                )

                boardOffset = clampedOffset(nextOffset, viewportSize: viewportSize)
            }
            .onEnded { _ in
                lastBoardOffset = boardOffset
            }
    }

    private func clampedOffset(_ offset: CGSize, viewportSize: CGSize) -> CGSize {
        let minX = min(0, viewportSize.width - boardSize.width)
        let minY = min(0, viewportSize.height - boardSize.height)

        let clampedX = min(0, max(minX, offset.width))
        let clampedY = min(0, max(minY, offset.height))

        return CGSize(width: clampedX, height: clampedY)
    }

    private func setInitialPositionIfNeeded(viewportSize: CGSize) {
        guard !hasSetInitialPosition else { return }

        let initialOffset = CGSize(
            width: (viewportSize.width - boardSize.width) / 2,
            height: (viewportSize.height - boardSize.height) / 2
        )

        boardOffset = clampedOffset(initialOffset, viewportSize: viewportSize)
        lastBoardOffset = boardOffset
        hasSetInitialPosition = true
    }

    // MARK: - Performance culling

    private func visibleItems(viewportSize: CGSize) -> [BoardMemoryItem] {
        let visibleRect = CGRect(
            x: -boardOffset.width - renderMargin,
            y: -boardOffset.height - renderMargin,
            width: viewportSize.width + renderMargin * 2,
            height: viewportSize.height + renderMargin * 2
        )

        return boardItems.filter { item in
            visibleRect.intersects(item.renderRect)
        }
    }

    // MARK: - Memory update

    private func updateMemory(_ updatedMemory: Memory, inAlbumId albumId: String) {
        guard var memories = albumMemories[albumId] else { return }

        if let index = memories.firstIndex(where: { $0.id == updatedMemory.id }) {
            memories[index] = updatedMemory
            albumMemories[albumId] = memories
        }
    }

    // MARK: - Similar memories

    private func similarMemories(for item: BoardMemoryItem) -> [SimilarMemoryEntry] {
        MemorySimilarity.similarMemories(
            for: item.memory,
            in: item.album,
            allMemories: allMemories,
            allAlbums: albums
        )
    }

    // MARK: - Board layout generation
    private func nonOverlappingPosition(
        for id: String,
        index: Int,
        size: CGFloat,
        placedItems: [BoardMemoryItem]
    ) -> CGPoint {
        let center = CGPoint(
            x: boardSize.width / 2,
            y: boardSize.height / 2
        )

        // First bubble starts from the middle of the board,
        // which is also the phone's initial viewing area.
        if placedItems.isEmpty {
            return center
        }

        let minimumGap: CGFloat = 42
        let ringSpacing: CGFloat = 230
        let slotsPerRing = 14
        let safePadding: CGFloat = 220

        // Try many candidate positions around the centre.
        // The search starts near the middle, then slowly expands outward.
        for attempt in 0..<260 {
            let ring = attempt / slotsPerRing + 1
            let slot = attempt % slotsPerRing

            let baseRadius = CGFloat(ring) * ringSpacing

            let radiusJitter = stableRandom(
                key: id,
                salt: 2000 + attempt,
                min: -38,
                max: 38
            )

            let angleJitter = stableRandom(
                key: id,
                salt: 3000 + attempt,
                min: -0.26,
                max: 0.26
            )

            let angle = CGFloat(slot) / CGFloat(slotsPerRing) * CGFloat.pi * 2 + angleJitter
            let radius = baseRadius + radiusJitter

            let candidate = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            let clampedCandidate = CGPoint(
                x: min(max(candidate.x, safePadding), boardSize.width - safePadding),
                y: min(max(candidate.y, safePadding), boardSize.height - safePadding)
            )

            if hasEnoughBubbleDistance(
                candidate: clampedCandidate,
                size: size,
                placedItems: placedItems,
                minimumGap: minimumGap
            ) {
                return clampedCandidate
            }
        }

        // Backup position if the board becomes very full.
        // This should rarely happen.
        let fallbackX = center.x + CGFloat(index % 5 - 2) * 260
        let fallbackY = center.y + CGFloat(index / 5) * 260

        return CGPoint(
            x: min(max(fallbackX, safePadding), boardSize.width - safePadding),
            y: min(max(fallbackY, safePadding), boardSize.height - safePadding)
        )
    }
    
    private func hasEnoughBubbleDistance(
        candidate: CGPoint,
        size: CGFloat,
        placedItems: [BoardMemoryItem],
        minimumGap: CGFloat
    ) -> Bool {
        for item in placedItems {
            let dx = candidate.x - item.position.x
            let dy = candidate.y - item.position.y
            let distance = sqrt(dx * dx + dy * dy)

            let requiredDistance = size / 2 + item.size / 2 + minimumGap

            if distance < requiredDistance {
                return false
            }
        }

        return true
    }
    

    private func boardBubbleSize(for id: String) -> CGFloat {
        stableRandom(
            key: id,
            salt: 300,
            min: 155,
            max: 215
        )
    }

    private func boardRotation(for id: String) -> Angle {
        let degrees = stableRandom(
            key: id,
            salt: 400,
            min: -9,
            max: 9
        )

        return .degrees(degrees)
    }

    private func stableRandom(
        key: String,
        salt: Int,
        min: CGFloat,
        max: CGFloat
    ) -> CGFloat {
        let input = "\(boardLayoutSeed)-\(key)-\(salt)"
        var hash: UInt64 = 14_695_981_039_346_656_037

        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        let normalized = CGFloat(hash % 10_000) / 10_000
        return min + normalized * (max - min)
    }
}

// MARK: - Board item

private struct BoardMemoryItem: Identifiable, Hashable {
    let memory: Memory
    let album: Album
    let position: CGPoint
    let size: CGFloat
    let rotation: Angle

    var id: String {
        memory.id
    }
    static func == (lhs: BoardMemoryItem, rhs: BoardMemoryItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var renderRect: CGRect {
        CGRect(
            x: position.x - size / 2 - 40,
            y: position.y - size / 2 - 60,
            width: size + 80,
            height: size + 120
        )
    }
}

// MARK: - Preview
#Preview {
    MainAlbumsContainerView()
        .environmentObject(LoginViewModel())
}
