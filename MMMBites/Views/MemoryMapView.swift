//
//  MemoryMapView.swift
//  MMMBites
//
//  Full-screen MapKit view that shows every memory with a coordinate as a
//  custom pin. Tap a pin → preview card → push to memory detail.
//

import SwiftUI
import MapKit

struct MemoryMapView: View {
    let memories: [Memory]
    let albums: [Album]

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMemoryID: String?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var memoriesWithLocation: [Memory] {
        memories.filter { $0.latitude != nil && $0.longitude != nil }
    }

    private var selectedMemory: Memory? {
        guard let id = selectedMemoryID else { return nil }
        return memoriesWithLocation.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if memoriesWithLocation.isEmpty {
                    AppBackground(variant: .warm)
                    emptyState
                } else {
                    mapView

                    if let selected = selectedMemory {
                        selectedMemoryCard(selected)
                            .padding(.horizontal, AppSpacing.l)
                            .padding(.bottom, AppSpacing.l)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(AppAnimation.snappy, value: selectedMemoryID)
            .navigationTitle("Memory Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if !memoriesWithLocation.isEmpty {
                    cameraPosition = .region(initialRegion)
                }
            }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $cameraPosition, selection: $selectedMemoryID) {
            ForEach(memoriesWithLocation) { memory in
                if let lat = memory.latitude, let lng = memory.longitude {
                    Annotation(
                        memory.title,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    ) {
                        pinView(for: memory, isSelected: memory.id == selectedMemoryID)
                    }
                    .tag(memory.id)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .ignoresSafeArea(edges: .bottom)
    }

    private func pinView(for memory: Memory, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .overlay(
                    Circle().stroke(
                        isSelected ? AppColor.primary : Color.white.opacity(0.9),
                        lineWidth: isSelected ? 2.5 : 1.5
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            if let mood = memory.mood {
                Text(mood.emoji)
                    .font(.system(size: isSelected ? 24 : 18))
            } else {
                Image(systemName: "fork.knife")
                    .font(.clash(isSelected ? 18 : 14, weight: .bold))
                    .foregroundStyle(AppGradient.hero)
            }
        }
        .scaleEffect(isSelected ? 1 : 1)
        .animation(AppAnimation.snappy, value: isSelected)
    }

    // MARK: - Selected memory card

    private func selectedMemoryCard(_ memory: Memory) -> some View {
        let parentAlbum = albums.first { $0.id == memory.albumId }
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
                    isCircle: false,
                    placeholderSystemImage: "fork.knife"
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if let mood = memory.mood {
                            Text(mood.emoji).font(.system(size: 13))
                        }
                        Text(memory.title)
                            .font(.clash(15, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                            .lineLimit(1)
                    }

                    if let location = memory.location, !location.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.clash(9, weight: .semibold))
                                .foregroundColor(AppColor.primary)
                            Text(location)
                                .font(.clash(11, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                                .lineLimit(1)
                        }
                    }

                    Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.clash(10, weight: .medium))
                        .foregroundColor(AppColor.inkFaint)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.clash(11, weight: .bold))
                    .foregroundColor(AppColor.inkFaint)
            }
            .padding(AppSpacing.m)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .pressableScale(0.98)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(AppGradient.glass)
                    .frame(width: 88, height: 88)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                Image(systemName: "map.fill")
                    .font(.clash(34, weight: .bold))
                    .foregroundStyle(AppGradient.hero)
            }

            Text("No mapped memories yet")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text("Pick a location from the suggestions when adding a memory and it'll land on this map.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, AppSpacing.xl)
        }
    }

    // MARK: - Initial region

    private var initialRegion: MKCoordinateRegion {
        let coordinates: [CLLocationCoordinate2D] = memoriesWithLocation.compactMap {
            guard let lat = $0.latitude, let lng = $0.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }

        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }

        if coordinates.count == 1 {
            return MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLng = lngs.min() ?? 0
        let maxLng = lngs.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (maxLat - minLat) * 1.4),
            longitudeDelta: max(0.02, (maxLng - minLng) * 1.4)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

