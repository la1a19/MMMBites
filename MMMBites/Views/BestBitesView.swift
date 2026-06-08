//
//  BestBitesView.swift
//  MMMBites
//
//  A curated gallery of bestBite quotes pulled across every memory.
//  Surfaces "the bites worth coming back for" — encourages users to fill
//  the bestBite field by giving that data a dedicated home.
//

import SwiftUI

struct BestBitesView: View {
    let memories: [Memory]
    let albums: [Album]

    @Environment(\.dismiss) private var dismiss

    private var bites: [Memory] {
        memories
            .filter { !($0.bestBite ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(spacing: AppSpacing.l) {
                        header

                        if bites.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: AppSpacing.m) {
                                ForEach(bites) { memory in
                                    biteCard(memory)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Best Bites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.s) {
            ZStack {
                Circle()
                    .fill(AppGradient.glass)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                Image(systemName: "fork.knife")
                    .font(.clash(28, weight: .bold))
                    .foregroundStyle(AppGradient.hero)
            }
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)

            VStack(spacing: 2) {
                Text(bites.isEmpty
                     ? "No best bites yet"
                     : "\(bites.count) \(bites.count == 1 ? "bite" : "bites") worth coming back for")
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.ink)
                Text("The single mouthful that made the meal.")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.m)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.s) {
            Image(systemName: "fork.knife")
                .font(.clash(42, weight: .light))
                .foregroundColor(AppColor.inkFaint)
            Text("Your bite gallery is empty")
                .font(AppFont.subheadline)
                .foregroundColor(AppColor.inkMuted)
            Text("Open a memory and fill in “the best bite” — they'll all collect here.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Bite card

    private func biteCard(_ memory: Memory) -> some View {
        let parentAlbum = albums.first { $0.id == memory.albumId }
        let bite = memory.bestBite ?? ""

        return NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: parentAlbum?.title ?? "Memory",
                album: parentAlbum
            )
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.m) {
                MemoryPhotoThumbnail(
                    photoData: memory.photoData,
                    imageURLs: memory.imageURLs,
                    width: 64,
                    height: 64,
                    isCircle: false,
                    placeholderSystemImage: "fork.knife"
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "quote.opening")
                            .font(.clash(12, weight: .bold))
                            .foregroundColor(AppColor.accent)
                        Text(bite)
                            .font(.clash(16, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                            .lineLimit(3)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    metadataRow(for: memory)
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.m)
            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .pressableScale(0.98)
    }

    private func metadataRow(for memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if let mood = memory.mood {
                    Text(mood.emoji).font(.system(size: 11))
                    Text("·")
                        .foregroundColor(AppColor.inkFaint)
                }
                Text(memory.title)
                    .font(.clash(11, weight: .semibold))
                    .foregroundColor(AppColor.inkMuted)
                    .lineLimit(1)
                Text("·")
                    .foregroundColor(AppColor.inkFaint)
                Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.clash(11, weight: .medium))
                    .foregroundColor(AppColor.inkFaint)
            }

            if let location = memory.location, !location.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "mappin")
                        .font(.clash(9, weight: .semibold))
                        .foregroundColor(AppColor.primary)
                    Text(location)
                        .font(.clash(10, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                        .lineLimit(1)
                }
            }
        }
    }
}
