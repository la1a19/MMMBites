//
//  AlbumsView.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var authViewModel: LoginViewModel
    @StateObject private var viewModel = AlbumsViewModel()

    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var selectedTags: Set<String> = []
    @State private var ownershipFilter: AlbumOwnershipFilter = .all
    @State private var showAddAlbum = false
    @State private var currentPage = 0
    @State private var showGridView = false
    @State private var showMemoryBoardView = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showFriends = false
    @State private var showMemorySearch = false
    @State private var showBestBites = false
    @State private var showMemoryMap = false
    @State private var profilePhotoData: Data?

    // Album-level categories shown in the filter sheet.
    // Combines built-in defaults, the user's saved custom tags, and any tag
    // currently in use across their albums — capitalised + deduped + sorted.
    private var filterOptions: [String] {
        var seen: Set<String> = []
        var ordered: [String] = []
        let sources: [String] =
            AlbumTagDefaults.all
            + (authViewModel.currentUser?.customTags ?? [])
            + viewModel.albums.flatMap(\.tags)
        for raw in sources {
            let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
            guard !normalized.isEmpty, seen.insert(normalized).inserted else { continue }
            ordered.append(normalized)
        }
        return ordered.sorted()
    }

    private var isAnyFilterActive: Bool {
        !selectedTags.isEmpty || ownershipFilter != .all
    }

    // Albums after applying selected tag filters + ownership + search text
    private var filteredAlbums: [Album] {
        let currentUserID = authViewModel.currentUser?.id
        return viewModel.albums.filter { album in
            let matchesTags = selectedTags.isEmpty ||
                !selectedTags.isDisjoint(with: Set(album.tags.map { $0.capitalized }))

            let matchesSearch = searchText.isEmpty || albumMatchesSearch(album)

            let matchesOwnership: Bool
            switch ownershipFilter {
            case .all:
                matchesOwnership = true
            case .mine:
                matchesOwnership = album.ownerId == currentUserID
            case .friends:
                matchesOwnership = album.ownerId != currentUserID
            }

            return matchesTags && matchesSearch && matchesOwnership
        }
    }

    private var currentUsername: String {
        authViewModel.currentUser?.username ?? "User"
    }

    private var currentUserEmail: String? {
        authViewModel.currentUser?.email
    }

    private var currentFriendCount: Int {
        authViewModel.currentUser?.friendIDs.count ?? 0
    }

    private var currentAvatarData: Data? {
        if let profilePhotoData {
            return profilePhotoData
        }
        guard let avatarData = authViewModel.currentUser?.avatarData else {
            return nil
        }
        return Data(base64Encoded: avatarData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if showMemoryBoardView {
                    VStack(spacing: AppSpacing.s) {
                        header
                            .padding(.horizontal, AppSpacing.xl)
                            .padding(.top, AppSpacing.s)
                        MemoryBoardView(
                            memories: viewModel.memories,
                            albums: viewModel.albums
                        )
                        .environmentObject(authViewModel)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.l) {
                            header
                                .bounceOnAppear()

                            titleRow
                                .bounceOnAppear(delay: 0.05)

                            searchRow
                                .bounceOnAppear(delay: 0.1)

                            if let throwback = throwbackMemory {
                                throwbackCard(throwback)
                                    .bounceOnAppear(delay: 0.12)
                            }

                            if bestBitesCount > 0 || mappedMemoriesCount > 0 {
                                HStack(spacing: AppSpacing.s) {
                                    if bestBitesCount > 0 {
                                        bestBitesEntryCard
                                    }
                                    if mappedMemoriesCount > 0 {
                                        mapEntryCard
                                    }
                                }
                                .bounceOnAppear(delay: 0.13)
                            }

                            sectionHeader
                                .bounceOnAppear(delay: 0.15)

                            bubblesCarousel
                                .bounceOnAppear(delay: 0.2)
                        }
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, AppSpacing.s)
                        .padding(.bottom, AppSpacing.xl)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .transition(.opacity)
                }
            }
            .sheet(isPresented: $showAddAlbum) {
                NavigationStack {
                    AddAlbumView(existingTags: filterOptions) { album in
                        Task {
                            await viewModel.add(album)
                            await MainActor.run {
                                currentPage = 0
                            }
                        }
                    }
                }
            }
            .task(id: authViewModel.currentUser?.id) {
                if let uid = authViewModel.currentUser?.id {
                    viewModel.startListening(for: uid)
                } else {
                    viewModel.stopListening()
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(
                    username: currentUsername,
                    email: currentUserEmail,
                    memoryCount: viewModel.memoryCount,
                    albumCount: viewModel.albums.count,
                    friendCount: currentFriendCount,
                    memories: viewModel.memories,
                    albums: viewModel.albums,
                    profilePhotoData: currentAvatarData
                ) { newPhotoData in
                    profilePhotoData = newPhotoData
                }
                .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showFriends) {
                FriendsSheet(memories: viewModel.memories, albums: viewModel.albums)
                    .environmentObject(authViewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMemorySearch) {
                MemorySearchView(
                    memories: viewModel.memories,
                    albums: viewModel.albums
                )
                .environmentObject(authViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showBestBites) {
                BestBitesView(
                    memories: viewModel.memories,
                    albums: viewModel.albums
                )
                .environmentObject(authViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMemoryMap) {
                MemoryMapView(
                    memories: viewModel.memories,
                    albums: viewModel.albums
                )
                .environmentObject(authViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFilterSheet) {
                AlbumFilterSheet(
                    availableTags: filterOptions,
                    customTags: authViewModel.currentUser?.customTags ?? [],
                    selectedTags: $selectedTags,
                    ownershipFilter: $ownershipFilter,
                    onAddTag: { newTag in
                        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
                        guard !trimmed.isEmpty else { return }
                        var existing = authViewModel.currentUser?.customTags ?? []
                        guard !existing.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
                        existing.append(trimmed)
                        Task { await authViewModel.updateCustomTags(existing) }
                    },
                    onRenameTag: { oldTag, newTag in
                        let trimmedOld = oldTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedNew = newTag.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
                        guard !trimmedOld.isEmpty, !trimmedNew.isEmpty,
                              trimmedOld.caseInsensitiveCompare(trimmedNew) != .orderedSame else { return }
                        // Update local selection if the renamed tag was selected
                        if selectedTags.contains(where: { $0.caseInsensitiveCompare(trimmedOld) == .orderedSame }) {
                            selectedTags = Set(selectedTags.map {
                                $0.caseInsensitiveCompare(trimmedOld) == .orderedSame ? trimmedNew : $0
                            })
                        }
                        // Update customTags + cascade across albums
                        var customs = authViewModel.currentUser?.customTags ?? []
                        if let idx = customs.firstIndex(where: { $0.caseInsensitiveCompare(trimmedOld) == .orderedSame }) {
                            customs[idx] = trimmedNew
                        }
                        Task {
                            await authViewModel.updateCustomTags(customs)
                            await viewModel.renameTagInAlbums(from: trimmedOld, to: trimmedNew)
                        }
                    },
                    onDeleteTag: { tag in
                        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        selectedTags = selectedTags.filter {
                            $0.caseInsensitiveCompare(trimmed) != .orderedSame
                        }
                        let customs = (authViewModel.currentUser?.customTags ?? []).filter {
                            $0.caseInsensitiveCompare(trimmed) != .orderedSame
                        }
                        Task {
                            await authViewModel.updateCustomTags(customs)
                            await viewModel.removeTagFromAlbums(trimmed)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert(
                "Couldn't sync albums",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                presenting: viewModel.errorMessage
            ) { _ in
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                AppColor.background,
                AppColor.secondary,
                AppColor.primary.opacity(0.65)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AppSpacing.s) {
            Button {
                Haptics.tap()
                withAnimation(AppAnimation.snappy) { 
                    showMemoryBoardView.toggle() 
                }
            } label: {
                Image(systemName: showMemoryBoardView ? "bubbles.and.sparkles.fill" : "bubbles.and.sparkles")
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 38, height: 38)
                    .fieldSurface(radius: AppRadius.s, fill: AppColor.surfaceGlass)
            }
            .buttonStyle(.plain)
            .pressableScale()

            Spacer()

            Button {
                Haptics.tap()
                showMemorySearch = true
            } label: {
                Image(systemName: "text.magnifyingglass")
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 34, height: 34)
                    .background(AppColor.surface.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.52), lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .pressableScale()

            Button {
                Haptics.tap()
                showFriends = true
            } label: {
                Image(systemName: "person.2.fill")
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 34, height: 34)
                    .background(AppColor.surface.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.52), lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .pressableScale()

            Menu {
                Button {
                    Haptics.tap()
                    showProfile = true
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                Button {
                    Haptics.tap()
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Divider()
                Button(role: .destructive) {
                    Haptics.warning()
                    authViewModel.logout()
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }

            } label: {
                HStack(spacing: 6) {
                    profileAvatar(size: 24)
                    Text(currentUsername)
                        .font(.clash(12, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Image(systemName: "chevron.down")
                        .font(.clash(9, weight: .bold))
                        .foregroundColor(AppColor.inkMuted)
                }
                .padding(.leading, 5)
                .padding(.trailing, 8)
                .frame(height: 34)
                .background(AppColor.surface.opacity(0.72), in: Capsule(style: .continuous))
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.52), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }
        }
    }

    @ViewBuilder
    private func profileAvatar(size: CGFloat) -> some View {
        if let currentAvatarData,
           let image = UIImage(data: currentAvatarData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        } else {
            AvatarView(initials: currentUsername, size: size)
        }
    }

    // MARK: - Title

    private var titleRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Albums")
                    .font(AppFont.display)
                    .foregroundStyle(AppGradient.heroText)
                Text("\(viewModel.albums.count) albums · \(viewModel.memoryCount) memories")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkMuted)
            }
            Spacer()
            Button {
                Haptics.soft()
                showAddAlbum = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.clash(16, weight: .bold))
                    Text("New Album")
                        .font(AppFont.captionBold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(AppGradient.hero))
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                .shadow(color: AppColor.primary.opacity(0.28), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .pressableScale()
        }
    }

    // MARK: - Search + filter

    private var searchRow: some View {
        HStack(spacing: AppSpacing.s) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColor.inkFaint)
                TextField("Search albums", text: $searchText)
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
            .frame(maxWidth: .infinity)
            .background(AppColor.surface.opacity(0.86), in: Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.58), lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 5, y: 2)

            Button {
                Haptics.tap()
                showFilterSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(isAnyFilterActive ? .white : AppColor.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(isAnyFilterActive ? AppColor.primary : AppColor.surface.opacity(0.88)))
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .animation(AppAnimation.snappy, value: searchText.isEmpty)
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(alignment: .center) {
            Text("Bite Bubbles")
                .font(AppFont.titleSmall)
                .foregroundColor(AppColor.ink)
            Spacer()
            if !filteredAlbums.isEmpty {
                Text("\(filteredAlbums.count)")
                    .font(AppFont.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppGradient.hero))
            }
        }
    }

    // MARK: - Bubbles carousel

    private var bubblesCarousel: some View {
        Group {
            if !viewModel.hasInitiallyLoaded {
                loadingPlaceholder
            } else if filteredAlbums.isEmpty {
                emptyState
            } else {
                carouselView
            }
        }
    }

    private var loadingPlaceholder: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 500)
    }

    private var carouselView: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(filteredAlbums.enumerated()), id: \.element.id) { index, album in
                VStack(spacing: AppSpacing.l) {
                    NavigationLink {
                        AlbumDetailView(
                            album: album,
                            crossAlbumMemories: viewModel.memories,
                            onAlbumUpdate: { updatedAlbum in
                                updateAlbum(updatedAlbum)
                            },
                            onAlbumDelete: { deletedAlbum in
                                deleteAlbum(deletedAlbum)
                            }
                        )
                    } label: {
                        photoBubble(album, isActive: index == currentPage)
                    }
                    .buttonStyle(.plain)

                    albumInfoCard(album)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 540)
        .animation(AppAnimation.smooth, value: currentPage)
    }

    private var currentAlbum: Album? {
        guard !filteredAlbums.isEmpty else { return nil }
        let safeIndex = min(max(currentPage, 0), filteredAlbums.count - 1)
        return filteredAlbums[safeIndex]
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.l) {
                ForEach(filteredAlbums) { album in
                    NavigationLink {
                        AlbumDetailView(
                            album: album,
                            crossAlbumMemories: viewModel.memories,
                            onAlbumUpdate: { updatedAlbum in
                                updateAlbum(updatedAlbum)
                            },
                            onAlbumDelete: { deletedAlbum in
                                deleteAlbum(deletedAlbum)
                            }
                        )
                    } label: {
                        gridCell(album)
                    }
                    .buttonStyle(.plain)
                    .pressableScale()
                }
            }
        }
        .frame(height: 500)
    }

    private func gridCell(_ album: Album) -> some View {
        VStack(spacing: AppSpacing.s) {
            ZStack {
                Circle()
                    .fill(AppGradient.hero.opacity(0.85))
                    .frame(width: 140, height: 140)
                    .blur(radius: 8)
                    .opacity(0.4)

                MemoryPhotoThumbnail(
                    photoData: coverPhotoData(for: album),
                    imageURLs: coverImageURLs(for: album),
                    width: 130,
                    height: 130
                )
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

            Text(album.title)
                .font(.clash(18, weight: .medium))
                .tracking(0.5)
                .foregroundColor(AppColor.ink)

            albumStatsLine(for: album)

            ownerByLine(for: album, size: 14, compact: true)
        }
        .padding(.vertical, AppSpacing.m)
    }

    // Compact one-liner stats — used on each album card so the detail page
    // doesn't have to repeat the same numbers.
    private func albumStatsLine(for album: Album) -> some View {
        let scoped = viewModel.memories.filter { $0.albumId == album.id }
        let memoryCount = scoped.count
        let reactionCount = scoped.reduce(0) { $0 + $1.reactions.count }
        let friendCount = Set(scoped.flatMap { $0.participantIds }).count

        return Text("\(memoryCount) memories · \(reactionCount) reactions · \(friendCount) friends")
            .font(AppFont.caption)
            .foregroundColor(AppColor.inkFaint)
            .lineLimit(1)
    }

    // Frame 1 — just the photo circle (swipeable)
    private func photoBubble(_ album: Album, isActive: Bool) -> some View {
        ZStack {
            // Radial-gradient halo. Fades to fully transparent at the edge of
            // its own frame, so even if the TabView page clips the visible
            // area, the clipped portion is already invisible — no sharp
            // rectangular boundary.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: AppColor.primary.opacity(isActive ? 0.55 : 0.18), location: 0.0),
                            .init(color: AppColor.secondary.opacity(isActive ? 0.30 : 0.10), location: 0.45),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 90,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            MemoryPhotoThumbnail(
                photoData: coverPhotoData(for: album),
                imageURLs: coverImageURLs(for: album),
                width: 280,
                height: 280,
                placeholderSystemImage: "photo.on.rectangle.angled"
            )

            // Bottom pill — shows the album's location, or falls back to
            // OPEN ALBUM when the album has no location set.
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

    // Frame 2 — separate info card (title + tags) shown below the photo
    private func albumInfoCard(_ album: Album) -> some View {
        VStack(spacing: AppSpacing.s) {
            Text(album.title)
                .font(.clash(26, weight: .medium))
                .tracking(1)
                .foregroundColor(AppColor.ink)

            albumStatsLine(for: album)

            ownerByLine(for: album, size: 20)

            // Hairline accent
            Rectangle()
                .fill(AppColor.inkFaint.opacity(0.25))
                .frame(width: 40, height: 1)

            // Tags
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

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: viewModel.albums.isEmpty ? "rectangle.stack.badge.plus" : "magnifyingglass")
                .font(.clash(42, weight: .light))
                .foregroundColor(AppColor.inkFaint)
                .frame(width: 92, height: 92)
                .background(AppGradient.glass, in: Circle())
            Text(viewModel.albums.isEmpty ? "Create your first album" : "No albums match your search")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text(viewModel.albums.isEmpty ? "Start with a place, trip, or food theme." : "Try a different search.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
            Button {
                if viewModel.albums.isEmpty {
                    showAddAlbum = true
                } else {
                    withAnimation(AppAnimation.snappy) {
                        searchText = ""
                    }
                }
                Haptics.tap()
            } label: {
                Text(viewModel.albums.isEmpty ? "New Album" : "Clear search")
                    .font(AppFont.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppGradient.hero))
            }
            .buttonStyle(.plain)
            .pressableScale()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
    }

    // MARK: - Discover entry cards

    private var bestBitesCount: Int {
        viewModel.memories.reduce(0) { count, memory in
            let trimmed = (memory.bestBite ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return count + (trimmed.isEmpty ? 0 : 1)
        }
    }

    private var mappedMemoriesCount: Int {
        viewModel.memories.reduce(0) { count, memory in
            count + ((memory.latitude != nil && memory.longitude != nil) ? 1 : 0)
        }
    }

    private var bestBitesEntryCard: some View {
        discoverCard(
            icon: "fork.knife",
            label: "BEST BITES",
            value: "\(bestBitesCount)",
            subtitle: bestBitesCount == 1 ? "bite" : "bites"
        ) {
            showBestBites = true
        }
    }

    private var mapEntryCard: some View {
        discoverCard(
            icon: "map.fill",
            label: "MAP",
            value: "\(mappedMemoriesCount)",
            subtitle: "on map"
        ) {
            showMemoryMap = true
        }
    }

    private func discoverCard(
        icon: String,
        label: String,
        value: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: AppSpacing.s) {
                ZStack {
                    Circle()
                        .fill(AppColor.accent.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.clash(13, weight: .bold))
                        .foregroundStyle(AppGradient.heroText)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.clash(9, weight: .semibold))
                        .tracking(1.1)
                        .foregroundStyle(AppGradient.heroText)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.clash(16, weight: .bold))
                            .foregroundColor(AppColor.ink)
                        Text(subtitle)
                            .font(.clash(11, weight: .medium))
                            .foregroundColor(AppColor.inkMuted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.s + 2)
            .padding(.vertical, AppSpacing.s + 2)
            .frame(maxWidth: .infinity)
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

    // MARK: - Throwback

    private var throwbackMemory: Memory? {
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let todayComp = calendar.dateComponents([.month, .day], from: today)

        // Only memories from a past year that share today's month + day.
        // No fallback — if nothing matches today, no throwback card is shown.
        return viewModel.memories
            .filter { memory in
                let comp = calendar.dateComponents([.month, .day], from: memory.date)
                return memory.date < startOfToday
                    && comp.month == todayComp.month
                    && comp.day == todayComp.day
            }
            .sorted { $0.date > $1.date }
            .first
    }

    private func throwbackLabel(for memory: Memory) -> String {
        let calendar = Calendar.current
        let nowYear = calendar.component(.year, from: Date())
        let memYear = calendar.component(.year, from: memory.date)
        let years = max(1, nowYear - memYear)
        return "ON THIS DAY · \(years) YEAR\(years == 1 ? "" : "S") AGO"
    }

    private func album(forMemory memory: Memory) -> Album? {
        viewModel.albums.first { $0.id == memory.albumId }
    }

    private func throwbackCard(_ memory: Memory) -> some View {
        let parentAlbum = album(forMemory: memory)
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
                    placeholderSystemImage: "clock.arrow.circlepath"
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(throwbackLabel(for: memory))
                        .font(.clash(10, weight: .semibold))
                        .tracking(1.1)
                        .foregroundStyle(AppGradient.heroText)
                        .lineLimit(1)

                    Text(memory.title)
                        .font(.clash(15, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let mood = memory.mood {
                            Text(mood.emoji).font(.system(size: 11))
                        }
                        if let location = memory.location, !location.isEmpty {
                            Text(location)
                                .font(.clash(10, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                                .lineLimit(1)
                        } else if !memory.participantIds.isEmpty {
                            Text("\(memory.participantIds.count) friend\(memory.participantIds.count == 1 ? "" : "s")")
                                .font(.clash(10, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.clash(11, weight: .bold))
                    .foregroundColor(AppColor.inkFaint)
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

    // MARK: - Helpers

    private func albumMatchesSearch(_ album: Album) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return album.title.localizedCaseInsensitiveContains(query)
        || (album.location?.localizedCaseInsensitiveContains(query) ?? false)
        || album.tags.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private func ownerDisplayName(for album: Album) -> String {
        if album.ownerId == authViewModel.currentUser?.id {
            return authViewModel.currentUser?.username ?? "User"
        }
        return viewModel.ownerUsers[album.ownerId]?.username ?? "Friend"
    }

    private func ownerAvatarImage(for album: Album) -> Image? {
        let base64: String?
        if album.ownerId == authViewModel.currentUser?.id {
            base64 = authViewModel.currentUser?.avatarData
        } else {
            base64 = viewModel.ownerUsers[album.ownerId]?.avatarData
        }
        guard
            let base64,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    private func ownerByLine(for album: Album, size: CGFloat = 18, compact: Bool = false) -> some View {
        HStack(spacing: 6) {
            AvatarView(
                avatar: ownerAvatarImage(for: album),
                initials: ownerDisplayName(for: album),
                size: size
            )
            Text("by \(ownerDisplayName(for: album))")
                .font(.clash(compact ? 10 : 11, weight: .semibold))
                .foregroundColor(AppColor.inkMuted)
                .lineLimit(1)
        }
    }

    private func coverPhotoData(for album: Album) -> [Data] {
        if let coverPhotoData = album.coverPhotoData {
            return [coverPhotoData]
        }

        return []
    }

    private func coverImageURLs(for album: Album) -> [String] {
        if let coverImageURL = album.coverImageURL {
            return [coverImageURL]
        }

        return []
    }

    private func updateAlbum(_ updatedAlbum: Album) {
        Task { await viewModel.update(updatedAlbum) }
    }

    private func deleteAlbum(_ deletedAlbum: Album) {
        Task { await viewModel.remove(deletedAlbum) }
    }
}

enum AlbumOwnershipFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mine = "Mine"
    case friends = "Friends"

    var id: String { rawValue }
}

private struct AlbumFilterSheet: View {
    let availableTags: [String]
    let customTags: [String]
    @Binding var selectedTags: Set<String>
    @Binding var ownershipFilter: AlbumOwnershipFilter
    let onAddTag: (String) -> Void
    let onRenameTag: (String, String) -> Void
    let onDeleteTag: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftSelectedTags: Set<String>
    @State private var draftOwnershipFilter: AlbumOwnershipFilter
    @State private var tagSearchText: String = ""
    @State private var showEditTags = false

    init(
        availableTags: [String],
        customTags: [String],
        selectedTags: Binding<Set<String>>,
        ownershipFilter: Binding<AlbumOwnershipFilter>,
        onAddTag: @escaping (String) -> Void,
        onRenameTag: @escaping (String, String) -> Void,
        onDeleteTag: @escaping (String) -> Void
    ) {
        self.availableTags = availableTags
        self.customTags = customTags
        self._selectedTags = selectedTags
        self._ownershipFilter = ownershipFilter
        self.onAddTag = onAddTag
        self.onRenameTag = onRenameTag
        self.onDeleteTag = onDeleteTag
        self._draftSelectedTags = State(initialValue: selectedTags.wrappedValue)
        self._draftOwnershipFilter = State(initialValue: ownershipFilter.wrappedValue)
    }

    private var visibleTags: [String] {
        let trimmed = tagSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return availableTags }
        return availableTags.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        ownershipSection
                        tagsSection
                    }
                    .padding(AppSpacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Filter albums")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        draftSelectedTags.removeAll()
                        draftOwnershipFilter = .all
                        tagSearchText = ""
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.clash(13, weight: .bold))
                            .foregroundColor(AppColor.ink)
                            .frame(width: 32, height: 32)
                            .glassCircleSurface()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.success()
                        selectedTags = draftSelectedTags
                        ownershipFilter = draftOwnershipFilter
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.clash(13, weight: .bold))
                            .foregroundColor(AppColor.ink)
                            .frame(width: 32, height: 32)
                            .glassCircleSurface()
                    }
                }
            }
            .sheet(isPresented: $showEditTags) {
                EditTagsSheet(
                    availableTags: availableTags,
                    customTags: customTags,
                    onAddTag: onAddTag,
                    onRenameTag: onRenameTag,
                    onDeleteTag: onDeleteTag
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var ownershipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OWNERSHIP")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.inkMuted)
            HStack(spacing: 8) {
                ForEach(AlbumOwnershipFilter.allCases) { option in
                    Button {
                        Haptics.selection()
                        draftOwnershipFilter = option
                    } label: {
                        Text(option.rawValue)
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundColor(draftOwnershipFilter == option ? .white : AppColor.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(
                                    draftOwnershipFilter == option
                                    ? AppColor.primary
                                    : Color.white.opacity(0.7)
                                )
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .pressableScale(0.96)
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TAGS")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.inkMuted)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColor.inkFaint)
                    TextField("Search tags", text: $tagSearchText)
                        .font(AppFont.body)
                        .autocorrectionDisabled()
                    if !tagSearchText.isEmpty {
                        Button {
                            tagSearchText = ""
                            Haptics.tap()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColor.inkFaint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(AppColor.surface.opacity(0.86), in: Capsule(style: .continuous))
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.58), lineWidth: 1))

                Button {
                    Haptics.tap()
                    showEditTags = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.clash(14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppGradient.hero))
                        .shadow(color: AppColor.primary.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .pressableScale(0.96)
            }

            if visibleTags.isEmpty {
                Text("No matching tags")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(visibleTags, id: \.self) { tag in
                        tagPill(tag)
                    }
                }
            }
        }
    }

    private func tagPill(_ tag: String) -> some View {
        let isSelected = draftSelectedTags.contains(tag)
        return Button {
            Haptics.selection()
            if isSelected {
                draftSelectedTags.remove(tag)
            } else {
                draftSelectedTags.insert(tag)
            }
        } label: {
            HStack {
                Text(tag)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.clash(13, weight: .bold))
                }
            }
            .font(AppFont.subheadline.weight(.semibold))
            .foregroundColor(isSelected ? .white : AppColor.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    isSelected
                    ? AppColor.tag(tag)
                    : Color.white.opacity(0.7)
                )
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .pressableScale(0.96)
    }
}

private struct EditTagsSheet: View {
    let availableTags: [String]
    let customTags: [String]
    let onAddTag: (String) -> Void
    let onRenameTag: (String, String) -> Void
    let onDeleteTag: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var newTagText: String = ""
    @State private var editingTag: String?
    @State private var editingTagDraft: String = ""
    @State private var tagPendingDeletion: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        addTagSection
                        tagListSection
                    }
                    .padding(AppSpacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.clash(13, weight: .bold))
                            .foregroundColor(AppColor.ink)
                            .frame(width: 32, height: 32)
                            .glassCircleSurface()
                    }
                }
            }
            .alert(
                "Delete tag?",
                isPresented: Binding(
                    get: { tagPendingDeletion != nil },
                    set: { if !$0 { tagPendingDeletion = nil } }
                ),
                presenting: tagPendingDeletion
            ) { tag in
                Button("Delete", role: .destructive) {
                    onDeleteTag(tag)
                    tagPendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    tagPendingDeletion = nil
                }
            } message: { tag in
                Text("Removing \"\(tag)\" will also remove it from every album that uses it.")
            }
        }
    }

    private var addTagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD NEW TAG")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.inkMuted)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "tag")
                        .foregroundColor(AppColor.inkFaint)
                    TextField("Tag name", text: $newTagText)
                        .font(AppFont.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onSubmit { commitNewTag() }
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(AppColor.surface.opacity(0.86), in: Capsule(style: .continuous))
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.58), lineWidth: 1))

                Button {
                    commitNewTag()
                } label: {
                    Image(systemName: "plus")
                        .font(.clash(14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppGradient.hero))
                        .shadow(color: AppColor.primary.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .pressableScale(0.94)
                .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
    }

    private var tagListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALL TAGS")
                .font(AppFont.captionBold)
                .foregroundColor(AppColor.inkMuted)

            if availableTags.isEmpty {
                Text("No tags yet")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(availableTags, id: \.self) { tag in
                        tagRow(tag)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tagRow(_ tag: String) -> some View {
        let isEditing = editingTag == tag
        HStack(spacing: 10) {
            Circle()
                .fill(AppColor.tag(tag))
                .frame(width: 14, height: 14)

            if isEditing {
                TextField("Tag name", text: $editingTagDraft)
                    .font(AppFont.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onSubmit { commitRename(of: tag) }
                Button("Save") {
                    commitRename(of: tag)
                }
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundColor(AppColor.primary)
                Button {
                    cancelEditing()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.inkFaint)
                }
                .buttonStyle(.plain)
            } else {
                Text(tag)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.ink)
                Spacer(minLength: 4)
                Button {
                    Haptics.tap()
                    editingTag = tag
                    editingTagDraft = tag
                } label: {
                    Image(systemName: "pencil")
                        .font(.clash(13, weight: .semibold))
                        .foregroundColor(AppColor.inkMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                Button {
                    Haptics.warning()
                    tagPendingDeletion = tag
                } label: {
                    Image(systemName: "trash")
                        .font(.clash(13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColor.primary.opacity(0.85)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                .stroke(Color.white.opacity(0.58), lineWidth: 1)
        )
    }

    private func commitNewTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddTag(trimmed)
        newTagText = ""
        Haptics.success()
    }

    private func commitRename(of original: String) {
        let trimmed = editingTagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.caseInsensitiveCompare(original) != .orderedSame else {
            cancelEditing()
            return
        }
        onRenameTag(original, trimmed)
        Haptics.success()
        cancelEditing()
    }

    private func cancelEditing() {
        editingTag = nil
        editingTagDraft = ""
    }
}

#Preview {
    AlbumsView()
        .environmentObject(LoginViewModel())
}
