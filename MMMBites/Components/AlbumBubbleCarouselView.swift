//
//  AlbumBubbleCarouselView.swift
//  MMMBites
//
//  Created by Yat Tin lee on 9/6/2026.
//

import SwiftUI

struct AlbumBubbleCarouselView: View {
    let albums: [Album]
    @Binding var currentPage: Int

    let memories: [Memory]

    let coverPhotoData: (Album) -> [Data]
    let coverImageURLs: (Album) -> [String]
    let ownerDisplayName: (Album) -> String
    let ownerAvatarImage: (Album) -> Image?

    let onAlbumUpdate: (Album) -> Void
    let onAlbumDelete: (Album) -> Void

    private var currentAlbum: Album? {
        guard !albums.isEmpty else { return nil }
        let safeIndex = min(max(currentPage, 0), albums.count - 1)
        return albums[safeIndex]
    }

    var body: some View {
        VStack(spacing: AppSpacing.l) {
            ZStack {
                carouselBackgroundGlow

                TabView(selection: $currentPage) {
                    ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                        NavigationLink {
                            AlbumDetailView(
                                album: album,
                                crossAlbumMemories: memories,
                                onAlbumUpdate: { updatedAlbum in
                                    onAlbumUpdate(updatedAlbum)
                                },
                                onAlbumDelete: { deletedAlbum in
                                    onAlbumDelete(deletedAlbum)
                                }
                            )
                        } label: {
                            photoBubble(album, isActive: index == currentPage)
                        }
                        .buttonStyle(.plain)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)
                .animation(AppAnimation.smooth, value: currentPage)
            }
            .frame(height: 340)


            albumScrollBar

            if let currentAlbum {
                albumInfoCard(currentAlbum)
                    .id(currentAlbum.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(AppAnimation.smooth, value: currentPage)
        .onChange(of: albums.count) { _, newCount in
            if currentPage >= newCount {
                currentPage = max(newCount - 1, 0)
            }
        }
    }
    
    private var carouselBackgroundGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: AppColor.primary.opacity(0.22), location: 0.0),
                        .init(color: AppColor.secondary.opacity(0.12), location: 0.45),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: .center,
                    startRadius: 45,
                    endRadius: 135
                )
            )
            .frame(width: 270, height: 270)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }
    
    private var albumScrollBar: some View {
        GeometryReader { geometry in
            let total = max(albums.count, 1)
            let trackWidth = geometry.size.width
            let thumbWidth = max(trackWidth / CGFloat(total), 34)
            let maxOffset = max(trackWidth - thumbWidth, 0)
            let progress = total > 1 ? CGFloat(currentPage) / CGFloat(total - 1) : 0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(height: 5)

                Capsule()
                    .fill(AppGradient.hero)
                    .frame(width: thumbWidth, height: 5)
                    .offset(x: maxOffset * progress)
                    .shadow(color: AppColor.primary.opacity(0.18), radius: 4, y: 2)
            }
        }
        .frame(height: 5)
        .padding(.horizontal, 90)
    }

    private func photoBubble(_ album: Album, isActive: Bool) -> some View {
        ZStack {

            MemoryPhotoThumbnail(
                photoData: coverPhotoData(album),
                imageURLs: coverImageURLs(album),
                width: 280,
                height: 280,
                placeholderSystemImage: "photo.on.rectangle.angled"
            )

            VStack {
                Spacer()
                bubblePill(for: album)
                    .padding(.bottom, 14)
                    .padding(.horizontal, 24)
            }
            .frame(width: 280, height: 280)
        }
        .frame(width: 340, height: 340)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 3)
                .frame(width: 280, height: 280)
        )
        .shadow(color: .black.opacity(0.16), radius: 20, y: 12)
        .scaleEffect(isActive ? 1.0 : 0.86)
        .opacity(isActive ? 1.0 : 0.55)
        .animation(AppAnimation.smooth, value: isActive)
    }

    @ViewBuilder
    private func bubblePill(for album: Album) -> some View {
        if let location = album.location, !location.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.clash(12, weight: .bold))

                Text(location)
                    .font(.clash(11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppGradient.glass, in: Capsule(style: .continuous))
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.clash(13, weight: .bold))

                Text("OPEN ALBUM")
                    .font(.clash(11, weight: .semibold))
                    .tracking(1.2)
            }
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppGradient.glass, in: Capsule(style: .continuous))
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }

    private func albumInfoCard(_ album: Album) -> some View {
        VStack(spacing: AppSpacing.m) {
            Text(album.title)
                .font(.clash(26, weight: .medium))
                .tracking(1)
                .foregroundColor(AppColor.ink)

            ownerByLine(for: album, size: 20)

            Rectangle()
                .fill(AppColor.inkFaint.opacity(0.25))
                .frame(width: 40, height: 1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(album.tags, id: \.self) { tag in
                        Text(tag.uppercased())
                            .font(.clash(10, weight: .semibold))
                            .tracking(1.2)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppColor.tag(tag)))
                            .shadow(color: AppColor.tag(tag).opacity(0.35), radius: 5, y: 2)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.l)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .fill(AppGradient.glass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
        .padding(.horizontal, AppSpacing.m)
    }

    private func ownerByLine(for album: Album, size: CGFloat = 18, compact: Bool = false) -> some View {
        HStack(spacing: 6) {
            AvatarView(
                avatar: ownerAvatarImage(album),
                initials: ownerDisplayName(album),
                size: size
            )

            Text("by \(ownerDisplayName(album))")
                .font(.clash(compact ? 10 : 11, weight: .semibold))
                .foregroundColor(AppColor.inkMuted)
                .lineLimit(1)
        }
    }
}
