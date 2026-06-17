//
//  MemoryBoardView.swift
//  MMMBites
//
//  Created by Yat Tin lee on 11/6/2026.
//


//
//  MemoryBoardView.swift
//  MMMBites
//
//  Created by Yat Tin lee on 9/6/2026.
//

import SwiftUI
import FirebaseFirestore

struct MemoryBoardView: View {
    let memories: [Memory]
    let albums: [Album]

    @EnvironmentObject var authViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var seenReactionMemoryIDs: Set<String> = []
    @State private var bubbleRefreshSeed = 0
    @State private var memoryOffsets: [String: CGSize] = [:]
    @State private var gestureStartOffsets: [String: CGSize] = [:]
    @State private var capturedByUsers: [User] = []

    // Canvas pan / zoom (Miro-like infinite board)
    @State private var canvasOffset: CGSize = .zero
    @State private var lastCanvasOffset: CGSize = .zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var lastCanvasScale: CGFloat = 1.0
    @State private var shouldShowInteractionHint = false

    private let maximumVisibleBubbles = 20
    private let canvasMultiplier: CGFloat = 2.6   // board is 2.6x the screen each axis
    private let minScale: CGFloat = 0.4
    private let maxScale: CGFloat = 3.0

    private var visibleMemories: [Memory] {
        memories
            .sorted {
                stableHash("\($0.id)-refresh-\(bubbleRefreshSeed)") <
                stableHash("\($1.id)-refresh-\(bubbleRefreshSeed)")
            }
            .prefix(maximumVisibleBubbles)
            .map { $0 }
    }

    private var hiddenMemoryCount: Int {
        max(memories.count - visibleMemories.count, 0)
    }

    var body: some View {
        GeometryReader { geometry in
            let vpW = geometry.size.width
            let vpH = geometry.size.height
            let vpCenter = CGPoint(x: vpW / 2, y: vpH / 2)

            ZStack {
                AppBackground()

                // Pan layer — empty area receives pan gesture
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                canvasOffset = CGSize(
                                    width: lastCanvasOffset.width + value.translation.width,
                                    height: lastCanvasOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastCanvasOffset = canvasOffset
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                canvasScale = min(max(lastCanvasScale * value, minScale), maxScale)
                            }
                            .onEnded { _ in
                                lastCanvasScale = canvasScale
                            }
                    )

                // Bubbles positioned in viewport coords with camera transform
                ForEach(Array(visibleMemories.enumerated()), id: \.element.id) { index, memory in
                    let baseOffset = radialOffset(for: memory, index: index, seed: bubbleRefreshSeed)
                    let userOffset = memoryOffsets[memory.id] ?? .zero
                    let worldX = baseOffset.x + userOffset.width
                    let worldY = baseOffset.y + userOffset.height
                    let screenX = vpCenter.x + (worldX + canvasOffset.width) * canvasScale
                    let screenY = vpCenter.y + (worldY + canvasOffset.height) * canvasScale

                    boardMemoryBubble(memory, index: index)
                        .scaleEffect(canvasScale)
                        .position(x: screenX, y: screenY)
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    if gestureStartOffsets[memory.id] == nil {
                                        gestureStartOffsets[memory.id] = memoryOffsets[memory.id] ?? .zero
                                    }
                                    let start = gestureStartOffsets[memory.id] ?? .zero
                                    memoryOffsets[memory.id] = CGSize(
                                        width: start.width + value.translation.width / canvasScale,
                                        height: start.height + value.translation.height / canvasScale
                                    )
                                }
                                .onEnded { _ in
                                    gestureStartOffsets.removeValue(forKey: memory.id)
                                    Haptics.soft()
                                }
                        )
                        .bounceOnAppear(delay: 0.04 + Double(index) * 0.012)
                }
            }
            .frame(width: vpW, height: vpH)
            .clipped()
            .overlay(alignment: .top) {
                if shouldShowInteractionHint {
                    boardInteractionHint
                        .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Haptics.tap()
                    withAnimation(AppAnimation.bouncy) {
                        bubbleRefreshSeed += 1
                        seenReactionMemoryIDs.removeAll()
                        memoryOffsets.removeAll()
                        canvasOffset = .zero
                        lastCanvasOffset = .zero
                        canvasScale = 1.0
                        lastCanvasScale = 1.0
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.65), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

                        VStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.clash(16, weight: .bold))
                                .foregroundColor(AppColor.primary)

                            if hiddenMemoryCount > 0 {
                                Text("+\(hiddenMemoryCount)")
                                    .font(.clash(8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColor.primary, in: Capsule())
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .pressableScale(0.95)
                .padding(.trailing, 30)
                .padding(.bottom, 40)
            }
            .onAppear(perform: presentInteractionHintIfNeeded)
            .task(id: capturedByIDs) {
                await loadCapturedByUsers()
            }
        }
    }

    // IDs we need user docs for, so the title pill can show the real username
    // / avatar instead of an initialised Firebase UID.
    private var capturedByIDs: [String] {
        Array(Set(memories.compactMap(\.capturedById))).sorted()
    }

    private func loadCapturedByUsers() async {
        let ids = capturedByIDs
        guard !ids.isEmpty else {
            capturedByUsers = []
            return
        }
        let database = Firestore.firestore()
        var loaded: [User] = []
        for chunk in ids.chunked(into: 30) {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                loaded.append(contentsOf: snapshot.documents.compactMap {
                    try? $0.data(as: User.self)
                })
            } catch {
                print("[MemoryBoardView] user load error: \(error)")
            }
        }
        capturedByUsers = loaded
    }

    private func userName(for id: String) -> String {
        if id == authViewModel.currentUser?.id {
            return authViewModel.currentUser?.username ?? "You"
        }
        return capturedByUsers.first(where: { $0.id == id })?.username ?? "Friend"
    }

    private func userAvatarImage(for id: String) -> Image? {
        let base64: String?
        if id == authViewModel.currentUser?.id {
            base64 = authViewModel.currentUser?.avatarData
        } else {
            base64 = capturedByUsers.first(where: { $0.id == id })?.avatarData
        }
        guard
            let base64,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    private var boardInteractionHint: some View {
        Text("✨ Pinch to zoom • Drag empty space to pan")
            .font(AppFont.captionBold)
            .foregroundColor(AppColor.ink)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, AppSpacing.m)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
            .allowsHitTesting(false)
    }

    private func presentInteractionHintIfNeeded() {
        guard authViewModel.shouldPresentMemoryBoardInteractionHint() else { return }

        withAnimation(AppAnimation.quick) {
            shouldShowInteractionHint = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(.easeOut(duration: 0.45)) {
                shouldShowInteractionHint = false
            }
        }
    }

    // MARK: - Background

    private func boardBackground(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.08))

            dreamyDotGrid(size: size)

            Circle()
                .fill(AppColor.primary.opacity(0.15))
                .frame(width: min(size.width, size.height) * 0.6)
                .blur(radius: 60)
                .position(x: size.width / 2, y: size.height / 2)

            Circle()
                .fill(AppColor.secondary.opacity(0.12))
                .frame(width: min(size.width, size.height) * 0.4)
                .blur(radius: 80)
                .position(x: size.width * 0.25, y: size.height * 0.75)

            Circle()
                .fill(AppColor.accent.opacity(0.12))
                .frame(width: min(size.width, size.height) * 0.45)
                .blur(radius: 80)
                .position(x: size.width * 0.75, y: size.height * 0.25)
        }
        .frame(width: size.width, height: size.height)
    }

    private func dreamyDotGrid(size: CGSize) -> some View {
        let spacing: CGFloat = max(80, min(size.width, size.height) / 8)
        let columns = Int(size.width / spacing)
        let rows = Int(size.height / spacing)

        return ZStack {
            ForEach(0...columns, id: \.self) { column in
                ForEach(0...rows, id: \.self) { row in
                    dreamyGridDot(column: column, row: row, spacing: spacing)
                }
            }
        }
    }

    private func dreamyGridDot(column: Int, row: Int, spacing: CGFloat) -> some View {
        let id = "dot-\(column)-\(row)"
        let baseSize = 4 + stableFraction(for: id, salt: 11) * 7
        let opacity = 0.12 + stableFraction(for: id, salt: 22) * 0.18
        let offsetX = (stableFraction(for: id, salt: 33) - 0.5) * 26
        let offsetY = (stableFraction(for: id, salt: 44) - 0.5) * 26

        let colorChoice = stableHash(id) % 3
        let dotColor: Color = {
            switch colorChoice {
            case 0:
                return AppColor.primary
            case 1:
                return AppColor.secondary
            default:
                return AppColor.accent
            }
        }()

        return Circle()
            .fill(dotColor.opacity(opacity))
            .frame(width: baseSize, height: baseSize)
            .blur(radius: 0.4)
            .shadow(color: dotColor.opacity(0.18), radius: 8, x: 0, y: 0)
            .position(
                x: CGFloat(column) * spacing + offsetX,
                y: CGFloat(row) * spacing + offsetY
            )
    }

    // MARK: - Positioning

    // Returns offset from origin (0,0). Index 0 = at center,
    // higher indexes spiral outward radially.
    private func radialOffset(for memory: Memory, index: Int, seed: Int = 0) -> CGPoint {
        if index == 0 {
            return .zero
        }
        let refreshSalt = seed * 1000
        let baseRadius: CGFloat = 110
        let radiusJitter = (stableFraction(for: memory.id, salt: refreshSalt + 11) - 0.5) * 40
        let radius = baseRadius * sqrt(CGFloat(index)) + radiusJitter

        let angleBase = stableFraction(for: memory.id, salt: refreshSalt + 91) * .pi * 2
        let angleNudge = CGFloat(index) * 0.6
        let angle = angleBase + angleNudge

        return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
    }

    // MARK: - Memory Bubble

    private func boardMemoryBubble(_ memory: Memory, index: Int) -> some View {
        let size = photoSize(for: memory.id)
        let hasUnseenReaction = shouldShowReactionAlert(for: memory)

        return NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: album(for: memory)?.title ?? "Memory",
                album: album(for: memory)
            )
        } label: {
            ZStack {
                if hasUnseenReaction {
                    reactionAlertRing(
                        size: size,
                        reactions: memory.reactions
                    )
                }

                VStack(spacing: AppSpacing.s) {
                    memoryPhotoCircle(memory, size: size)

                    memoryTitlePill(memory)
                        .padding(.horizontal, 4)
                }
                .frame(width: bubbleFrameWidth(for: memory.id))
                .modifier(BoardFloatingMotion(seed: floatSeed(for: memory.id)))
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                if hasUnseenReaction {
                    seenReactionMemoryIDs.insert(memory.id)
                }
            }
        )
    }

    private func shouldShowReactionAlert(for memory: Memory) -> Bool {
        guard !memory.reactions.isEmpty else { return false }
        return !seenReactionMemoryIDs.contains(memory.id)
    }

    private func reactionAlertRing(size: CGFloat, reactions: [Reaction]) -> some View {
        let emojis = uniqueReactionEmojis(from: reactions)
        let ringSize1 = size + 72
        let ringSize2 = size + 118
        let ringSize3 = size + 164

        return ZStack {
            Circle()
                .stroke(AppColor.primary.opacity(0.48), lineWidth: 3)
                .frame(width: ringSize1, height: ringSize1)
                .modifier(BoardPulseMotion(delay: 0))

            Circle()
                .stroke(AppColor.secondary.opacity(0.36), lineWidth: 2)
                .frame(width: ringSize2, height: ringSize2)
                .modifier(BoardPulseMotion(delay: 0.22))

            Circle()
                .stroke(AppColor.accent.opacity(0.28), lineWidth: 1.5)
                .frame(width: ringSize3, height: ringSize3)
                .modifier(BoardPulseMotion(delay: 0.44))

            ForEach(Array(emojis.prefix(5).enumerated()), id: \.offset) { index, emoji in
                reactionEmojiPop(
                    emoji: emoji,
                    index: index,
                    total: min(emojis.count, 5),
                    radius: ringSize2 / 2
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func uniqueReactionEmojis(from reactions: [Reaction]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        for reaction in reactions {
            if !seen.contains(reaction.emoji) {
                seen.insert(reaction.emoji)
                result.append(reaction.emoji)
            }
        }

        return result
    }

    private func reactionEmojiPop(
        emoji: String,
        index: Int,
        total: Int,
        radius: CGFloat
    ) -> some View {
        let safeTotal = max(total, 1)
        let angle = (CGFloat(index) / CGFloat(safeTotal)) * .pi * 2 - .pi / 2
        let x = cos(angle) * radius
        let y = sin(angle) * radius

        return Text(emoji)
            .font(.system(size: 24))
            .padding(7)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            .offset(x: x, y: y)
            .modifier(BoardEmojiPopMotion(delay: Double(index) * 0.16))
    }

    private func memoryPhotoCircle(_ memory: Memory, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(AppGradient.hero)
                .frame(width: size + 8, height: size + 8)
                .blur(radius: 14)
                .opacity(0.3)

            MemoryPhotoThumbnail(
                photoData: memory.photoData,
                imageURLs: memory.imageURLs,
                width: size,
                height: size
            )
        }
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }

    private func memoryTitlePill(_ memory: Memory) -> some View {
        let avatarTrailing = avatarOnTrailing(for: memory.id)
        return HStack(spacing: 6) {
            if !avatarTrailing, let capturedById = memory.capturedById {
                avatarChip(for: capturedById)
            }
            Text(memory.title)
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundColor(AppColor.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            if avatarTrailing, let capturedById = memory.capturedById {
                avatarChip(for: capturedById)
            }
        }
        .padding(.leading, (memory.capturedById != nil && !avatarTrailing) ? 6 : 12)
        .padding(.trailing, (memory.capturedById != nil && avatarTrailing) ? 6 : 12)
        .padding(.vertical, 5)
        .background(Color.white, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func avatarChip(for userID: String) -> some View {
        AvatarView(
            avatar: userAvatarImage(for: userID),
            initials: userName(for: userID),
            size: 22,
            showRing: true
        )
    }

    // Mirror AlbumDetailView's deterministic side choice so the same memory
    // shows its avatar on the same side in both views.
    private func avatarOnTrailing(for id: String) -> Bool {
        stableHash(id) % 2 == 0
    }

    // MARK: - Helpers

    private func album(for memory: Memory) -> Album? {
        albums.first { $0.id == memory.albumId }
    }

    // MARK: - Stable Random Helpers

    private func stableHash(_ id: String) -> Int {
        var hash = 5381

        for byte in id.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ Int(byte)
        }

        return abs(hash)
    }

    private func stableFraction(for id: String, salt: Int) -> CGFloat {
        let saltedHash = stableHash("\(id)-\(salt)")
        return CGFloat(saltedHash % 10_000) / 10_000
    }

    private func photoSize(for id: String) -> CGFloat {
        // Continuous random size in [100, 165] — feels more organic than 4 fixed sizes
        let minSize: CGFloat = 100
        let maxSize: CGFloat = 165
        return minSize + stableFraction(for: id, salt: 555) * (maxSize - minSize)
    }

    private func bubbleFrameWidth(for id: String) -> CGFloat {
        photoSize(for: id) + 44
    }

    private func floatSeed(for id: String) -> Double {
        Double(stableHash(id) % 1000) / 1000.0 * .pi * 2
    }
}

// MARK: - Animation Modifiers

private struct BoardFloatingMotion: ViewModifier {
    let seed: Double

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let xSpeed = 0.42 + seed.truncatingRemainder(dividingBy: 0.28)
            let ySpeed = 0.34 + seed.truncatingRemainder(dividingBy: 0.22)
            let xAmplitude = 3.5 + CGFloat(seed.truncatingRemainder(dividingBy: 2.6))
            let yAmplitude = 5.0 + CGFloat(seed.truncatingRemainder(dividingBy: 3.4))
            let dx = CGFloat(sin(t * xSpeed + seed)) * xAmplitude
            let dy = CGFloat(cos(t * ySpeed + seed * 1.3)) * yAmplitude

            content.offset(x: dx, y: dy)
        }
    }
}

private struct BoardPulseMotion: ViewModifier {
    let delay: Double

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate + delay
            let wave = (sin(t * 2.4) + 1) / 2
            let scale = 0.92 + CGFloat(wave) * 0.16
            let opacity = 0.35 + CGFloat(1 - wave) * 0.45

            content
                .scaleEffect(scale)
                .opacity(opacity)
        }
    }
}

private struct BoardEmojiPopMotion: ViewModifier {
    let delay: Double

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate + delay
            let wave = (sin(t * 2.8) + 1) / 2

            let scale = 0.88 + CGFloat(wave) * 0.22
            let yOffset = -4 + CGFloat(wave) * -8
            let opacity = 0.68 + CGFloat(wave) * 0.32

            content
                .scaleEffect(scale)
                .offset(y: yOffset)
                .opacity(opacity)
        }
    }
}

#Preview {
    NavigationStack {
        MemoryBoardView(
            memories: MockData.memories(forAlbumId: MockData.albumPark.id),
            albums: [MockData.albumPark]
        )
        .environmentObject(LoginViewModel())
    }
}
