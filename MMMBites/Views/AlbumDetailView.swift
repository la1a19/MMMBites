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
    var onAlbumUpdate: ((Album) -> Void)?
    var onAlbumDelete: ((Album) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: LoginViewModel
    @StateObject private var memoriesViewModel = MemoriesViewModel()
    @State private var searchText = ""
    @State private var showEditAlbum = false
    @State private var friendUsers: [User] = []
    @State private var isBubbleCanvasExpanded = false
    @State private var bubbleCanvasOffset: CGSize = .zero
    @GestureState private var bubbleDragTranslation: CGSize = .zero

    init(
        album: Album,
        initialMemories: [Memory]? = nil,
        onAlbumUpdate: ((Album) -> Void)? = nil,
        onAlbumDelete: ((Album) -> Void)? = nil
    ) {
        _album = State(initialValue: album)
        self.onAlbumUpdate = onAlbumUpdate
        self.onAlbumDelete = onAlbumDelete
        self.initialMemories = initialMemories ?? []
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

    private var totalReactionCount: Int {
        memories.reduce(0) { $0 + $1.reactions.count }
    }

    private var participantCount: Int {
        Set(memories.flatMap(\.participantIds)).count
    }

    private var participantIDs: [String] {
        Array(Set(album.friendIds + memories.flatMap(\.participantIds) + memories.compactMap(\.capturedById)))
            .sorted()
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    if isBubbleCanvasExpanded {
                        compactAlbumBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        albumHeaderCard
                            .bounceOnAppear()

                        albumActionRow
                            .bounceOnAppear(delay: 0.05)

                        searchField
                            .bounceOnAppear(delay: 0.1)

                        summaryRow
                            .bounceOnAppear(delay: 0.12)
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                            onAlbumDelete?(album)
                            dismiss()
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
                AddAlbumView(albumToEdit: album) { updatedAlbum in
                    withAnimation(AppAnimation.snappy) {
                        album = updatedAlbum
                    }
                    onAlbumUpdate?(updatedAlbum)
                }
            }
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
                .foregroundStyle(AppGradient.hero)
        }
    }

    private func openLocationInMaps(_ location: String) {
        Haptics.tap()
        if let lat = album.latitude, let lon = album.longitude {
            let mapLocation = CLLocation(latitude: lat, longitude: lon)
            let item = MKMapItem(location: mapLocation, address: nil)
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
                    bubbleCanvasOffset = .zero
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
                    .foregroundStyle(AppGradient.hero)
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

    private var summaryRow: some View {
        HStack(spacing: AppSpacing.s) {
            summaryChip(icon: "photo.stack.fill", title: "\(memories.count)", subtitle: "memories")
            summaryChip(icon: "heart.fill", title: "\(totalReactionCount)", subtitle: "reactions", tint: AppColor.primary)
            summaryChip(icon: "person.2.fill", title: "\(participantCount)", subtitle: "people", tint: AppColor.secondary)
        }
    }

    private func addMemoryButton(compact: Bool) -> some View {
        NavigationLink {
            AddMemoryView(album: album) { newMemory in
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

    // MARK: - Summary chip

    private func summaryChip(icon: String, title: String, subtitle: String, tint: Color = AppColor.accent) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.clash(14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.18)))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(AppFont.captionBold)
                    .foregroundColor(AppColor.ink)
                Text(subtitle)
                    .font(AppFont.tiny)
                    .foregroundColor(AppColor.inkFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .fieldSurface()
    }

    // MARK: - Memory bubble

    // MARK: - Free-form memory canvas

    private var freeformMemoryCanvas: some View {
        GeometryReader { proxy in
            let viewportSize = proxy.size
            let contentSize = bubbleCanvasContentSize(
                viewportSize: viewportSize,
                memoryCount: filteredMemories.count
            )
            let liveOffset = clampedCanvasOffset(
                proposed: CGSize(
                    width: bubbleCanvasOffset.width + bubbleDragTranslation.width,
                    height: bubbleCanvasOffset.height + bubbleDragTranslation.height
                ),
                viewportSize: viewportSize,
                contentSize: contentSize
            )

            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())

                ZStack(alignment: .topLeading) {
                    ForEach(Array(filteredMemories.enumerated()), id: \.element.id) { index, memory in
                        memoryBubble(memory)
                            .position(bubblePosition(
                                for: memory,
                                index: index,
                                contentSize: contentSize
                            ))
                            .zIndex(Double(stableHash(memory.id) % 100))
                            .bounceOnAppear(delay: 0.12 + Double(index) * 0.035)
                    }
                }
                .frame(width: contentSize.width, height: contentSize.height, alignment: .topLeading)
                .offset(liveOffset)
            }
            .clipped()
            .simultaneousGesture(bubbleCanvasDragGesture(
                viewportSize: viewportSize,
                contentSize: contentSize
            ))
        }
        .frame(height: bubbleCanvasViewportHeight(for: filteredMemories.count, expanded: isBubbleCanvasExpanded))
        .onChange(of: filteredMemories.map(\.id)) { _, _ in
            bubbleCanvasOffset = .zero
        }
    }

    private func bubbleCanvasViewportHeight(for memoryCount: Int, expanded: Bool) -> CGFloat {
        if expanded {
            return 760
        }
        return min(660, max(500, CGFloat(memoryCount) * 78 + 260))
    }

    private func bubbleCanvasContentSize(viewportSize: CGSize, memoryCount: Int) -> CGSize {
        CGSize(
            width: max(viewportSize.width * 1.75, viewportSize.width + 280),
            height: max(viewportSize.height * 1.75, CGFloat(memoryCount) * 150 + 260)
        )
    }

    private func bubbleCanvasDragGesture(viewportSize: CGSize, contentSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($bubbleDragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                if value.translation.height < -90 {
                    withAnimation(AppAnimation.snappy) {
                        isBubbleCanvasExpanded = true
                    }
                    Haptics.selection()
                } else if value.translation.height > 90 {
                    withAnimation(AppAnimation.snappy) {
                        isBubbleCanvasExpanded = false
                    }
                    Haptics.selection()
                }

                let proposed = CGSize(
                    width: bubbleCanvasOffset.width + value.translation.width,
                    height: bubbleCanvasOffset.height + value.translation.height
                )
                bubbleCanvasOffset = clampedCanvasOffset(
                    proposed: proposed,
                    viewportSize: viewportSize,
                    contentSize: contentSize
                )
            }
    }

    private func clampedCanvasOffset(
        proposed: CGSize,
        viewportSize: CGSize,
        contentSize: CGSize
    ) -> CGSize {
        let minX = min(0, viewportSize.width - contentSize.width)
        let minY = min(0, viewportSize.height - contentSize.height)
        return CGSize(
            width: min(max(proposed.width, minX), 0),
            height: min(max(proposed.height, minY), 0)
        )
    }

    private func bubblePosition(for memory: Memory, index: Int, contentSize: CGSize) -> CGPoint {
        let size = photoSize(for: memory.id)
        let margin = size / 2 + 22
        let xRange = max(1, contentSize.width - margin * 2)
        let yRange = max(1, contentSize.height - margin * 2)
        let x = margin + stableFraction(for: memory.id, salt: 13) * xRange
        let verticalStep = min(150, yRange / CGFloat(max(filteredMemories.count, 1)))
        let yJitter = (stableFraction(for: memory.id, salt: 47) - 0.5) * 92
        let y = margin + 96 + CGFloat(index) * verticalStep + yJitter

        return CGPoint(
            x: min(max(x, margin), contentSize.width - margin),
            y: min(max(y, margin), contentSize.height - margin)
        )
    }

    private func memoryBubble(_ memory: Memory) -> some View {
        let size = photoSize(for: memory.id)
        let avatarTrailing = avatarOnTrailing(for: memory.id)

        return NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: album.title,
                album: album,
                similarMemories: similarMemories(for: memory),
                onUpdate: { updated in
                    Task {
                        await memoriesViewModel.update(updated)
                    }
                },
                onDelete: { deleted in
                    Task {
                        await memoriesViewModel.remove(deleted)
                    }
                }
            )
        } label: {
            VStack(spacing: AppSpacing.s) {
                memoryPhotoCircle(memory, size: size)
                memoryTitlePill(memory, avatarTrailing: avatarTrailing)
                    .padding(.horizontal, 4)
            }
            .frame(width: bubbleFrameWidth(for: memory.id))
            .modifier(FloatingMotion(seed: floatSeed(for: memory.id)))
        }
        .buttonStyle(.plain)
        .pressableScale()
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
                    AddMemoryView(album: album) { newMemory in
                        Task {
                            await memoriesViewModel.add(newMemory)
                        }
                    }
                } label: {
                    Text("Start a Meal Memory")
                        .font(AppFont.captionBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppGradient.hero))
                }
                .buttonStyle(.plain)
                .pressableScale()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

// Continuous, organic drift for the memory bubbles. The seed changes phase,
// speed and amplitude, so nearby bubbles do not move in lockstep.
private struct FloatingMotion: ViewModifier {
    let seed: Double

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let xSpeed = 0.42 + (seed.truncatingRemainder(dividingBy: 0.28))
            let ySpeed = 0.34 + (seed.truncatingRemainder(dividingBy: 0.22))
            let xAmplitude = 3.5 + CGFloat(seed.truncatingRemainder(dividingBy: 2.6))
            let yAmplitude = 5.0 + CGFloat(seed.truncatingRemainder(dividingBy: 3.4))
            let dx = CGFloat(sin(t * xSpeed + seed)) * xAmplitude
            let dy = CGFloat(cos(t * ySpeed + seed * 1.3)) * yAmplitude
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
