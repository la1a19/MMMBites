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

struct MemoryBoardView: View {
    let memories: [Memory]
    let albums: [Album]

    @EnvironmentObject var authViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var seenReactionMemoryIDs: Set<String> = []
    @State private var bubbleRefreshSeed = 0
    @State private var memoryOffsets: [String: CGSize] = [:]

    private let maximumVisibleBubbles = 28

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
            ZStack {
                AppBackground()

                ZStack {
                    boardBackground(size: geometry.size)

                    ForEach(Array(visibleMemories.enumerated()), id: \.element.id) { index, memory in
                        boardMemoryBubble(memory, index: index)
                            .position(responsiveBoardPosition(
                                for: memory,
                                index: index,
                                in: geometry.size,
                                seed: bubbleRefreshSeed
                            ))
                            .offset(memoryOffsets[memory.id] ?? .zero)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let bubbleSize = photoSize(for: memory.id)
                                        let allowedOverflow: CGFloat = 20
                                        let titleHeight: CGFloat = 80 // Estimated height for section header
                                        
                                        let maxX = geometry.size.width/2 - bubbleSize/2 + allowedOverflow
                                        let minX = -geometry.size.width/2 + bubbleSize/2 - allowedOverflow
                                        let maxY = geometry.size.height/2 - bubbleSize/2 + allowedOverflow
                                        let minY = -geometry.size.height/2 + bubbleSize/2 + titleHeight - allowedOverflow
                                        
                                        let constrainedX = min(max(value.translation.width, minX), maxX)
                                        let constrainedY = min(max(value.translation.height, minY), maxY)
                                        
                                        memoryOffsets[memory.id] = CGSize(width: constrainedX, height: constrainedY)
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            memoryOffsets[memory.id] = .zero
                                        }
                                        Haptics.soft()
                                    }
                            )
                            .bounceOnAppear(delay: 0.04 + Double(index) * 0.012)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            Haptics.tap()
                            withAnimation(AppAnimation.bouncy) {
                                bubbleRefreshSeed += 1
                                seenReactionMemoryIDs.removeAll()
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
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 40)
                }
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

    private func responsiveBoardPosition(
        for memory: Memory,
        index: Int,
        in size: CGSize,
        seed: Int = 0
    ) -> CGPoint {
        let bubbleSize = photoSize(for: memory.id)
        let margin = bubbleSize / 2 + 40
        let refreshSalt = seed * 1000

        // Center the first few memories
        if index < min(6, visibleMemories.count) {
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            if index == 0 {
                return CGPoint(x: centerX, y: centerY)
            }
            
            let radius: CGFloat = min(size.width, size.height) * 0.15 + CGFloat(index % 3) * min(size.width, size.height) * 0.08
            let angle = stableFraction(for: memory.id, salt: refreshSalt + 91) * .pi * 2
            
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            
            return CGPoint(
                x: min(max(x, margin), size.width - margin),
                y: min(max(y, margin), size.height - margin)
            )
        }
        
        // Distribute remaining memories
        let xRange = size.width - margin * 2
        let yRange = size.height - margin * 2
        
        let x = margin + stableFraction(for: memory.id, salt: refreshSalt + 13) * xRange
        let y = margin + stableFraction(for: memory.id, salt: refreshSalt + 47) * yRange
        
        return CGPoint(x: x, y: y)
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
