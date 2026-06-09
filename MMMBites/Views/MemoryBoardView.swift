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

    private let boardSize: CGFloat = 2400
    private let centerID = "board-center-anchor"

    var body: some View {
        ZStack {
            AppBackground()

            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        boardBackground

                        Color.clear
                            .frame(width: 1, height: 1)
                            .position(x: boardSize / 2, y: boardSize / 2)
                            .id(centerID)

                        ForEach(Array(memories.enumerated()), id: \.element.id) { index, memory in
                            boardMemoryBubble(memory, index: index)
                                .position(boardPosition(for: memory, index: index))
                                .bounceOnAppear(delay: 0.04 + Double(index) * 0.012)
                        }
                    }
                    .frame(width: boardSize, height: boardSize)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(centerID, anchor: .center)
                    }
                }
            }

            topOverlay
        }
        .navigationBarBackButtonHidden(true)
    }

    private var boardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 64, style: .continuous)
                .fill(Color.white.opacity(0.12))

            Circle()
                .fill(AppColor.primary.opacity(0.12))
                .frame(width: 520, height: 520)
                .blur(radius: 90)
                .position(x: boardSize / 2, y: boardSize / 2)

            Circle()
                .fill(AppColor.secondary.opacity(0.10))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .position(x: boardSize * 0.28, y: boardSize * 0.72)

            Circle()
                .fill(AppColor.accent.opacity(0.10))
                .frame(width: 460, height: 460)
                .blur(radius: 100)
                .position(x: boardSize * 0.78, y: boardSize * 0.25)
        }
        .frame(width: boardSize, height: boardSize)
    }

    private var topOverlay: some View {
        VStack {
            HStack {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.clash(15, weight: .bold))
                        .foregroundColor(AppColor.ink)
                        .frame(width: 38, height: 38)
                        .glassCircleSurface()
                }
                .buttonStyle(.plain)
                .pressableScale()

                VStack(alignment: .leading, spacing: 1) {
                    Text("Memory Board")
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.ink)

                    Text("\(memories.count) memories")
                        .font(AppFont.tiny)
                        .foregroundColor(AppColor.inkMuted)
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.m)

            Spacer()
        }
    }

    private func boardMemoryBubble(_ memory: Memory, index: Int) -> some View {
        let size = photoSize(for: memory.id)
        let hasUnseenReaction = shouldShowReactionAlert(for: memory)

        return NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: album(for: memory)?.title ?? "Memory",
                album: album(for: memory),
                onUpdate: { updatedMemory in
                    updateMemory(updatedMemory)
                },
                onDelete: { deletedMemory in
                    deleteMemory(deletedMemory)
                }
            )
            .environmentObject(authViewModel)
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
        .pressableScale()
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
        HStack(spacing: 6) {
            if let capturedById = memory.capturedById {
                AvatarView(
                    initials: capturedById,
                    size: 22,
                    showRing: true
                )
            }

            Text(memory.title)
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundColor(AppColor.ink)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.leading, memory.capturedById == nil ? 12 : 6)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .background(Color.white, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func album(for memory: Memory) -> Album? {
        albums.first { $0.id == memory.albumId }
    }

    private func updateMemory(_ memory: Memory) {
        var updated = memory
        updated.updatedAt = Date()

        Task {
            do {
                try Firestore.firestore()
                    .collection("memories")
                    .document(updated.id)
                    .setData(from: updated, merge: true)
            } catch {
                print("[MemoryBoardView] memory update error: \(error)")
            }
        }
    }

    private func deleteMemory(_ memory: Memory) {
        Task {
            do {
                try await Firestore.firestore()
                    .collection("memories")
                    .document(memory.id)
                    .delete()
            } catch {
                print("[MemoryBoardView] memory delete error: \(error)")
            }
        }
    }

    // MARK: - Board positioning

    private func boardPosition(for memory: Memory, index: Int) -> CGPoint {
        let size = photoSize(for: memory.id)
        let margin = size / 2 + 80

        // First few bubbles appear around the middle of the 2400 x 2400 board.
        if index < min(6, memories.count) {
            let center = boardSize / 2
            let radius: CGFloat = index == 0 ? 0 : 150 + CGFloat(index % 3) * 70
            let angle = stableFraction(for: memory.id, salt: 91) * .pi * 2

            let x = center + cos(angle) * radius
            let y = center + sin(angle) * radius

            return CGPoint(
                x: min(max(x, margin), boardSize - margin),
                y: min(max(y, margin), boardSize - margin)
            )
        }

        // Other bubbles are randomly spread across the whole board.
        let xRange = boardSize - margin * 2
        let yRange = boardSize - margin * 2

        let x = margin + stableFraction(for: memory.id, salt: 13) * xRange
        let y = margin + stableFraction(for: memory.id, salt: 47) * yRange

        return CGPoint(x: x, y: y)
    }

    // MARK: - Stable random helpers

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
        let sizes: [CGFloat] = [112, 126, 140, 154]
        return sizes[stableHash(id) % sizes.count]
    }

    private func bubbleFrameWidth(for id: String) -> CGFloat {
        photoSize(for: id) + 44
    }

    private func floatSeed(for id: String) -> Double {
        Double(stableHash(id) % 1000) / 1000.0 * .pi * 2
    }
}

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
