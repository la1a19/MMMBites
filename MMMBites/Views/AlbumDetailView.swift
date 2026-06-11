//
//  AlbumDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct AlbumDetailView: View {
    @State private var album: Album
    private let initialMemories: [Memory]
    let crossAlbumMemories: [Memory]
    var onAlbumUpdate: ((Album) -> Void)?
    var onAlbumDelete: ((Album) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: LoginViewModel
    @StateObject private var memoriesViewModel = MemoriesViewModel()
    @State private var searchText = ""
    @State private var showEditAlbum = false
    @State private var friendUsers: [User] = []
    @State private var isBubbleCanvasExpanded = false
    @State private var bubbleOffsets: [String: CGSize] = [:]
    @State private var gestureStartOffsets: [String: CGSize] = [:]
    @State private var navigationMemoryID: String?
    @State private var showDeleteAlbumConfirmation = false

    // Miro-style canvas pan / zoom state
    @State private var canvasOffset: CGSize = .zero
    @State private var lastCanvasOffset: CGSize = .zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var lastCanvasScale: CGFloat = 1.0
    @State private var shuffleSeed: Int = 0
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 2.5

    init(
        album: Album,
        initialMemories: [Memory]? = nil,
        crossAlbumMemories: [Memory] = [],
        onAlbumUpdate: ((Album) -> Void)? = nil,
        onAlbumDelete: ((Album) -> Void)? = nil
    ) {
        _album = State(initialValue: album)
        self.onAlbumUpdate = onAlbumUpdate
        self.onAlbumDelete = onAlbumDelete
        self.initialMemories = initialMemories ?? []
        self.crossAlbumMemories = crossAlbumMemories
    }

    private var currentUserID: String? {
        authViewModel.currentUser?.id
    }

    private var canEditAlbum: Bool {
        album.ownerId == currentUserID
    }

    private var memories: [Memory] {
        memoriesViewModel.memories.isEmpty ? initialMemories : memoriesViewModel.memories
    }

    private var locationHintMemories: [Memory] {
        var seenIDs: Set<String> = []
        return (memories + crossAlbumMemories).filter { memory in
            seenIDs.insert(memory.id).inserted
        }
    }

    /// Up to 3 related memories from the same real album.
    private func similarMemories(for memory: Memory) -> [SimilarMemoryEntry] {
        MemorySimilarity.similarMemories(
            for: memory,
            in: album,
            allMemories: memories,
            allAlbums: [album]
        )
    }

    // Memories filtered by the search text
    private var filteredMemories: [Memory] {
        if searchText.isEmpty {
            return memories
        }
        return memories.filter(memoryMatchesSearch(_:))
    }

    private var participantIDs: [String] {
        var ids = Set(album.friendIds + memories.flatMap(\.participantIds) + memories.compactMap(\.capturedById))
        ids.insert(album.ownerId)
        return Array(ids).sorted()
    }

    private var ownerDisplayName: String {
        if album.ownerId == currentUserID {
            return authViewModel.currentUser?.username ?? "User"
        }
        return friendUsers.first(where: { $0.id == album.ownerId })?.username ?? "Friend"
    }

    private var ownerAvatarImage: Image? {
        let base64: String?
        if album.ownerId == currentUserID {
            base64 = authViewModel.currentUser?.avatarData
        } else {
            base64 = friendUsers.first(where: { $0.id == album.ownerId })?.avatarData
        }
        guard
            let base64,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    @ViewBuilder
    private var ownerByLine: some View {
        HStack(spacing: 6) {
            AvatarView(
                avatar: ownerAvatarImage,
                initials: ownerDisplayName,
                size: 22
            )
            Text("by \(ownerDisplayName)")
                .font(AppFont.caption.weight(.semibold))
                .foregroundColor(hasCoverArt ? .white.opacity(0.95) : AppColor.inkMuted)
                .shadow(color: hasCoverArt ? .black.opacity(0.45) : .clear, radius: 4, y: 1)
                .lineLimit(1)
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    if !isBubbleCanvasExpanded {
                        albumHeaderCard
                            .bounceOnAppear()

                        albumActionRow
                            .bounceOnAppear(delay: 0.05)

                        searchField
                            .bounceOnAppear(delay: 0.1)
                    }

                    // Memories live on a draggable free-form canvas, so they
                    // can sit partly off-screen and be pulled into view.
                    if filteredMemories.isEmpty {
                        emptyState
                    } else {
                        freeformMemoryCanvas
                            .padding(.top, AppSpacing.s)
                    }
                }
                .padding(AppSpacing.xl)
                .animation(AppAnimation.snappy, value: isBubbleCanvasExpanded)
            }
            .simultaneousGesture(
                // Swipe up anywhere on the page → collapse header.
                // Swipe down → expand. Works alongside normal scroll.
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        let threshold: CGFloat = 50
                        if value.translation.height < -threshold && !isBubbleCanvasExpanded {
                            withAnimation(AppAnimation.snappy) {
                                isBubbleCanvasExpanded = true
                            }
                        } else if value.translation.height > threshold && isBubbleCanvasExpanded {
                            withAnimation(AppAnimation.snappy) {
                                isBubbleCanvasExpanded = false
                            }
                        }
                    }
            )

            // Pinned floating shuffle button — never scrolls off-screen.
            if !filteredMemories.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingShuffleButton
                    }
                }
                .padding(.trailing, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navigationMemoryID) { id in
            if let memory = memories.first(where: { $0.id == id }) {
                MemoryDetailView(
                    memory: memory,
                    albumTitle: album.title,
                    album: album,
                    similarMemories: similarMemories(for: memory),
                    onUpdate: { updated in
                        Task { await memoriesViewModel.update(updated) }
                    },
                    onDelete: { deleted in
                        Task { await memoriesViewModel.remove(deleted) }
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.clash(14, weight: .bold))
                        .foregroundColor(AppColor.ink)
                        .frame(width: 32, height: 32)
                        .glassCircleSurface()
                }
            }
            if isBubbleCanvasExpanded {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(album.title)
                            .font(AppFont.headline)
                            .foregroundStyle(AppGradient.heroText)
                            .lineLimit(1)
                        Text("\(memories.count) memories")
                            .font(AppFont.tiny)
                            .foregroundColor(AppColor.inkFaint)
                    }
                }
            }
            if canEditAlbum {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Haptics.tap()
                            showEditAlbum = true
                        } label: {
                            Label("Edit album", systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            Haptics.warning()
                            showDeleteAlbumConfirmation = true
                        } label: {
                            Label("Delete album", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.clash(16, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                            .frame(width: 34, height: 34)
                            .glassCircleSurface()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showEditAlbum) {
            NavigationStack {
                AddAlbumView(
                    albumToEdit: album,
                    existingTags: authViewModel.currentUser?.customTags ?? []
                ) { updatedAlbum in
                    withAnimation(AppAnimation.snappy) {
                        album = updatedAlbum
                    }
                    onAlbumUpdate?(updatedAlbum)
                }
            }
        }
        .alert("Delete album?", isPresented: $showDeleteAlbumConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Haptics.warning()
                onAlbumDelete?(album)
                dismiss()
            }
        } message: {
            Text("This will permanently delete \"\(album.title)\" and all \(memories.count) memor\(memories.count == 1 ? "y" : "ies") in it. This can't be undone.")
        }
        .task(id: album.id) {
            memoriesViewModel.startListening(forAlbumID: album.id)
        }
        .task(id: participantIDs) {
            await loadUsers()
        }
        .alert(
            "Couldn't sync memories",
            isPresented: Binding(
                get: { memoriesViewModel.errorMessage != nil },
                set: { if !$0 { memoriesViewModel.errorMessage = nil } }
            ),
            presenting: memoriesViewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { memoriesViewModel.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Header card

    private var hasCoverArt: Bool {
        if album.coverPhotoData != nil { return true }
        if let url = album.coverImageURL, !url.isEmpty { return true }
        return false
    }

    @ViewBuilder
    private var albumHeaderCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            albumTitleText

            ownerByLine

            if let location = album.location, !location.isEmpty {
                Button {
                    openLocationInMaps(location)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(hasCoverArt ? Color.white.opacity(0.95) : AppColor.primary)
                        Text(location)
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundColor(hasCoverArt ? .white : AppColor.inkMuted)
                            .shadow(color: hasCoverArt ? .black.opacity(0.45) : .clear, radius: 4, y: 1)
                        Image(systemName: "arrow.up.right")
                            .font(.clash(10, weight: .bold))
                            .foregroundColor(hasCoverArt ? Color.white.opacity(0.85) : AppColor.primary.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                .pressableScale(0.97)
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
                                .shadow(color: AppColor.tag(tag).opacity(0.45), radius: 4, y: 2)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(hasCoverArt ? AppSpacing.l : 0)
        .background(coverCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            if hasCoverArt {
                RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            }
        }
        .shadow(color: hasCoverArt ? .black.opacity(0.18) : .clear, radius: 16, y: 8)
    }

    @ViewBuilder
    private var albumTitleText: some View {
        if hasCoverArt {
            Text(album.title)
                .font(AppFont.displayLarge)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.55), radius: 10, y: 2)
        } else {
            Text(album.title)
                .font(AppFont.displayLarge)
                .foregroundStyle(AppGradient.heroText)
        }
    }

    private func openLocationInMaps(_ location: String) {
        Haptics.tap()
        if let lat = album.latitude, let lon = album.longitude {
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            let item = MKMapItem(placemark: placemark)
            item.name = location
            item.openInMaps(launchOptions: [
                MKLaunchOptionsMapTypeKey: NSNumber(value: MKMapType.standard.rawValue)
            ])
            return
        }

        let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }

    @ViewBuilder
    private var coverCardBackground: some View {
        if hasCoverArt {
            ZStack {
                if let coverData = album.coverPhotoData,
                   let image = UIImage(data: coverData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 2)
                } else if let urlString = album.coverImageURL,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill().blur(radius: 2)
                    } placeholder: {
                        Rectangle().fill(AppColor.bgMint)
                    }
                }

                // Soft gradient — keeps food photo recognisable while still
                // anchoring contrast for the title and tags.
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.18), location: 0.0),
                        .init(color: .black.opacity(0.05), location: 0.5),
                        .init(color: .black.opacity(0.5), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - User lookup

    private func loadUsers() async {
        let ids = participantIDs
        guard !ids.isEmpty else {
            friendUsers = []
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
                print("[AlbumDetailView] user load error: \(error)")
            }
        }
        friendUsers = loaded
    }

    private func userName(for id: String) -> String {
        friendUsers.first(where: { $0.id == id })?.username ?? id
    }

    private func userAvatarImage(for id: String) -> Image? {
        guard
            let base64 = friendUsers.first(where: { $0.id == id })?.avatarData,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    private func memoryMatchesSearch(_ memory: Memory) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return memory.title.localizedCaseInsensitiveContains(query)
        || (memory.note?.localizedCaseInsensitiveContains(query) ?? false)
        || (memory.bestBite?.localizedCaseInsensitiveContains(query) ?? false)
        || (memory.location?.localizedCaseInsensitiveContains(query) ?? false)
        || memory.memorableTags.contains { $0.localizedCaseInsensitiveContains(query) }
        || (memory.mood?.label.localizedCaseInsensitiveContains(query) ?? false)
    }

    private var compactAlbumBar: some View {
        HStack(spacing: AppSpacing.m) {
            Button {
                withAnimation(AppAnimation.snappy) {
                    isBubbleCanvasExpanded = false
                    bubbleOffsets = [:]
                }
                Haptics.selection()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.clash(13, weight: .bold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 32, height: 32)
                    .glassCircleSurface()
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(album.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppGradient.heroText)
                    .lineLimit(1)
                Text("\(memories.count) memories")
                    .font(AppFont.tiny)
                    .foregroundColor(AppColor.inkFaint)
            }

            Spacer()

            addMemoryButton(compact: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColor.surface.opacity(0.82), in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.58), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var albumActionRow: some View {
        HStack {
            HStack(spacing: -10) {
                ForEach(Array(participantIDs.prefix(3)), id: \.self) { userID in
                    AvatarView(
                        avatar: userAvatarImage(for: userID),
                        initials: userName(for: userID),
                        size: 34,
                        showRing: true
                    )
                }
                if participantIDs.count > 3 {
                    Text("+\(participantIDs.count - 3)")
                        .font(AppFont.captionBold)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(AppColor.secondary))
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }

            Spacer()

            addMemoryButton(compact: false)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColor.inkFaint)
            TextField("Search memories", text: $searchText)
                .font(AppFont.subheadline)
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
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(AppColor.surface.opacity(0.86), in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.58), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        .animation(AppAnimation.snappy, value: searchText)
    }

    private func addMemoryButton(compact: Bool) -> some View {
        NavigationLink {
            AddMemoryView(
                album: album,
                existingMemories: locationHintMemories
            ) { newMemory in
                Task {
                    await memoriesViewModel.add(newMemory)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "fork.knife")
                    .font(.clash(compact ? 12 : 13, weight: .bold))
                if !compact {
                    Text("Start a Meal Memory")
                        .font(AppFont.subheadline.weight(.semibold))
                }
            }
            .foregroundColor(.white)
            .frame(width: compact ? 36 : nil, height: compact ? 36 : nil)
            .padding(.horizontal, compact ? 0 : 16)
            .padding(.vertical, compact ? 0 : 12)
            .background(Capsule().fill(AppGradient.hero))
            .shadow(color: AppColor.primary.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .pressableScale()
    }

    // MARK: - Memory bubble

    // MARK: - Free-form memory canvas

    private var freeformMemoryCanvas: some View {
        GeometryReader { proxy in
            let vpW = proxy.size.width
            let vpH = proxy.size.height
            let vpCenter = CGPoint(x: vpW / 2, y: vpH / 2)

            ZStack {
                // Pan layer — empty space receives pan and pinch
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                canvasOffset = CGSize(
                                    width: lastCanvasOffset.width + value.translation.width,
                                    height: lastCanvasOffset.height + value.translation.height
                                )
                                // Header collapse based on the current gesture's
                                // direction, not accumulated pan. Swipe up → hide
                                // header. Swipe down → reveal it. Works from any
                                // starting position, like Instagram/Twitter.
                                let threshold: CGFloat = 50
                                if value.translation.height < -threshold && !isBubbleCanvasExpanded {
                                    withAnimation(AppAnimation.snappy) {
                                        isBubbleCanvasExpanded = true
                                    }
                                } else if value.translation.height > threshold && isBubbleCanvasExpanded {
                                    withAnimation(AppAnimation.snappy) {
                                        isBubbleCanvasExpanded = false
                                    }
                                }
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

                ForEach(Array(filteredMemories.enumerated()), id: \.element.id) { index, memory in
                    let baseOffset = radialOffset(for: memory.id, index: index, seed: shuffleSeed)
                    let userOffset = bubbleOffsets[memory.id] ?? .zero
                    let worldX = baseOffset.x + userOffset.width
                    let worldY = baseOffset.y + userOffset.height
                    let screenX = vpCenter.x + (worldX + canvasOffset.width) * canvasScale
                    let screenY = vpCenter.y + (worldY + canvasOffset.height) * canvasScale

                    memoryBubble(memory)
                        .scaleEffect(canvasScale)
                        .position(x: screenX, y: screenY)
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    if gestureStartOffsets[memory.id] == nil {
                                        gestureStartOffsets[memory.id] = bubbleOffsets[memory.id] ?? .zero
                                    }
                                    let start = gestureStartOffsets[memory.id] ?? .zero
                                    bubbleOffsets[memory.id] = CGSize(
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
        }
        .frame(height: bubbleCanvasViewportHeight(for: filteredMemories.count, expanded: isBubbleCanvasExpanded))
        .clipped()
        .onChange(of: filteredMemories.map(\.id)) { _, ids in
            let validIDs = Set(ids)
            bubbleOffsets = bubbleOffsets.filter { validIDs.contains($0.key) }
        }
    }

    // Floating shuffle button — lives on the outer ZStack so it stays
    // anchored to the screen and never scrolls away with the canvas.
    private var floatingShuffleButton: some View {
        Button {
            Haptics.tap()
            withAnimation(AppAnimation.bouncy) {
                shuffleSeed += 1
                bubbleOffsets.removeAll()
                canvasOffset = .zero
                lastCanvasOffset = .zero
                canvasScale = 1.0
                lastCanvasScale = 1.0
                isBubbleCanvasExpanded = false
            }
        } label: {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 52, height: 52)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.65), lineWidth: 1.5)
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.clash(15, weight: .bold))
                        .foregroundColor(AppColor.primary)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .pressableScale(0.95)
    }

    // Returns offset from origin. Index 0 = center, higher indexes spiral outward.
    private func radialOffset(for id: String, index: Int, seed: Int = 0) -> CGPoint {
        if index == 0 { return .zero }
        let refreshSalt = seed * 1000
        let baseRadius: CGFloat = 110
        let radiusJitter = (stableFraction(for: id, salt: refreshSalt + 11) - 0.5) * 40
        let radius = baseRadius * sqrt(CGFloat(index)) + radiusJitter

        let angleBase = stableFraction(for: id, salt: refreshSalt + 91) * .pi * 2
        let angleNudge = CGFloat(index) * 0.6
        let angle = angleBase + angleNudge

        return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
    }

    private func bubbleCanvasViewportHeight(for memoryCount: Int, expanded: Bool) -> CGFloat {
        if expanded {
            return 760
        }
        return min(660, max(500, CGFloat(memoryCount) * 78 + 260))
    }

    private func memoryBubble(_ memory: Memory) -> some View {
        let size = photoSize(for: memory.id)
        let avatarTrailing = avatarOnTrailing(for: memory.id)

        return VStack(spacing: AppSpacing.s) {
            memoryPhotoCircle(memory, size: size)
            memoryTitlePill(memory, avatarTrailing: avatarTrailing)
                .padding(.horizontal, 4)
        }
        .frame(width: bubbleFrameWidth(for: memory.id))
        .modifier(FloatingMotion(seed: floatSeed(for: memory.id), isActive: true))
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            navigationMemoryID = memory.id
        }
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

    private func memoryTitlePill(_ memory: Memory, avatarTrailing: Bool) -> some View {
        HStack(spacing: 6) {
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

    // MARK: - Deterministic free-form helpers

    private func stableHash(_ id: String) -> Int {
        // String.hashValue is per-process random; use a stable djb2 hash so
        // each memory keeps the same size/position across cold starts.
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

    private func avatarOnTrailing(for id: String) -> Bool {
        stableHash(id) % 2 == 0
    }

    private func bubbleHorizontalNudge(for id: String) -> CGFloat {
        let mod = stableHash(id) % 25   // 0...24
        return CGFloat(mod) - 12        // -12...12
    }

    private func bubbleVerticalNudge(for id: String) -> CGFloat {
        CGFloat((stableHash(id) / 7) % 18)
    }

    private func floatSeed(for id: String) -> Double {
        Double(stableHash(id) % 1000) / 1000.0 * .pi * 2
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "photo.stack")
                .font(.clash(44, weight: .light))
                .foregroundColor(AppColor.inkFaint)
                .padding(.top, 40)
            Text(memories.isEmpty ? "Add your first meal memory" : "No memories found")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text(memories.isEmpty ? "Save a photo and title now. Details can come later." : "Try a different search or add another memory.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
            if memories.isEmpty {
                NavigationLink {
                    AddMemoryView(
                        album: album,
                        existingMemories: locationHintMemories
                    ) { newMemory in
                        Task {
                            await memoriesViewModel.add(newMemory)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.clash(20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppGradient.hero))
                        .shadow(color: AppColor.primary.opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .pressableScale()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

// Continuous, organic drift for the memory bubbles. Pauses entirely whenever
// any bubble is being dragged so the gesture stream doesn't fight a 60fps
// timeline re-render on every other bubble.
private struct FloatingMotion: ViewModifier {
    let seed: Double
    var isActive: Bool = true

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let xSpeed = 0.42 + (seed.truncatingRemainder(dividingBy: 0.28))
            let ySpeed = 0.34 + (seed.truncatingRemainder(dividingBy: 0.22))
            let xAmplitude = 3.5 + CGFloat(seed.truncatingRemainder(dividingBy: 2.6))
            let yAmplitude = 5.0 + CGFloat(seed.truncatingRemainder(dividingBy: 3.4))
            let dx = isActive ? CGFloat(sin(t * xSpeed + seed)) * xAmplitude : 0
            let dy = isActive ? CGFloat(cos(t * ySpeed + seed * 1.3)) * yAmplitude : 0
            content.offset(x: dx, y: dy)
        }
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(
            album: MockData.albumPark,
            initialMemories: MockData.memories(forAlbumId: MockData.albumPark.id)
        )
    }
    .environmentObject(LoginViewModel())
}
