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
    @State private var showFilters = false
    @State private var selectedTags: Set<String> = []
    @State private var showAddAlbum = false
    @State private var currentPage = 0
    @State private var showGridView = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var profilePhotoData: Data?

    // Album-level categories shown when the filter panel is open.
    private let filterOptions = AlbumTagDefaults.filters

    // Albums after applying selected tag filters + search text
    private var filteredAlbums: [Album] {
        viewModel.albums.filter { album in
            let matchesTags = selectedTags.isEmpty ||
                !selectedTags.isDisjoint(with: Set(album.tags.map { $0.capitalized }))

            let matchesSearch = searchText.isEmpty || albumMatchesSearch(album)

            return matchesTags && matchesSearch
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

                VStack(spacing: AppSpacing.l) {
                    header
                        .bounceOnAppear()

                    titleRow
                        .bounceOnAppear(delay: 0.05)

                    searchRow
                        .bounceOnAppear(delay: 0.1)

                    if showFilters {
                        filterPills
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    sectionHeader
                        .bounceOnAppear(delay: 0.15)

                    bubblesCarousel
                        .bounceOnAppear(delay: 0.2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.s)
            }
            .sheet(isPresented: $showAddAlbum) {
                NavigationStack {
                    AddAlbumView { album in
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
                    profilePhotoData: currentAvatarData
                ) { newPhotoData in
                    profilePhotoData = newPhotoData
                }
                .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
                Color(red: 0.78, green: 0.90, blue: 0.88),
                Color(red: 0.96, green: 0.93, blue: 0.80),
                Color(red: 0.80, green: 0.90, blue: 0.96)
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
                withAnimation(AppAnimation.snappy) { showGridView.toggle() }
            } label: {
                Image(systemName: showGridView ? "rectangle.stack.fill" : "square.grid.2x2.fill")
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 38, height: 38)
                    .fieldSurface(radius: AppRadius.s, fill: AppColor.surfaceGlass)
            }
            .buttonStyle(.plain)
            .pressableScale()

            Spacer()
            
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

    // MARK: - Filter pills

    private var filterPills: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(filterOptions, id: \.self) { tag in
                Button {
                    Haptics.selection()
                    withAnimation(AppAnimation.snappy) { toggleTag(tag) }
                } label: {
                    HStack {
                        Text(tag)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        if selectedTags.contains(tag) {
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.clash(13, weight: .bold))
                        }
                    }
                    .font(AppFont.subheadline)
                    .foregroundColor(selectedTags.contains(tag) ? .white : AppColor.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            selectedTags.contains(tag)
                            ? AppColor.tag(tag)
                            : Color.white.opacity(0.7)
                        )
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .pressableScale(0.94)
            }
        }
    }

    // MARK: - Title

    private var titleRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Albums")
                    .font(AppFont.display)
                    .foregroundStyle(AppGradient.hero)
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
                withAnimation(AppAnimation.snappy) { showFilters.toggle() }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(showFilters ? .white : AppColor.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(showFilters ? AppColor.primary : AppColor.surface.opacity(0.88)))
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .animation(AppAnimation.snappy, value: searchText.isEmpty)
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(alignment: .center) {
            Text(showGridView ? "Album Grid" : "Bite Bubbles")
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
            } else if showGridView {
                gridView
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
        VStack(spacing: AppSpacing.l) {
            // Frame 1 — swipeable photo bubbles
            TabView(selection: $currentPage) {
                ForEach(Array(filteredAlbums.enumerated()), id: \.element.id) { index, album in
                    NavigationLink {
                        AlbumDetailView(
                            album: album,
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
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 340)
            .animation(AppAnimation.smooth, value: currentPage)

            // Frame 2 — separate info card that animates when currentPage changes
            if let currentAlbum = currentAlbum {
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
        }
        .padding(.vertical, AppSpacing.m)
    }

    // Frame 1 — just the photo circle (swipeable)
    private func photoBubble(_ album: Album, isActive: Bool) -> some View {
        ZStack {
            Circle()
                .fill(AppGradient.hero)
                .frame(width: 300, height: 300)
                .blur(radius: 30)
                .opacity(isActive ? 0.45 : 0.15)

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
        VStack(spacing: AppSpacing.m) {
            Text(album.title)
                .font(.clash(26, weight: .medium))
                .tracking(1)
                .foregroundColor(AppColor.ink)

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
            Image(systemName: viewModel.albums.isEmpty ? "rectangle.stack.badge.plus" : "line.3.horizontal.decrease.circle")
                .font(.clash(42, weight: .light))
                .foregroundColor(AppColor.inkFaint)
                .frame(width: 92, height: 92)
                .background(AppGradient.glass, in: Circle())
            Text(viewModel.albums.isEmpty ? "Create your first album" : "No albums match your filters")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text(viewModel.albums.isEmpty ? "Start with a place, trip, or food theme." : "Try clearing tags or a different search.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
            Button {
                if viewModel.albums.isEmpty {
                    showAddAlbum = true
                } else {
                    withAnimation(AppAnimation.snappy) {
                        selectedTags.removeAll()
                        searchText = ""
                    }
                }
                Haptics.tap()
            } label: {
                Text(viewModel.albums.isEmpty ? "New Album" : "Reset filters")
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

    // MARK: - Helpers

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func albumMatchesSearch(_ album: Album) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return album.title.localizedCaseInsensitiveContains(query)
        || (album.location?.localizedCaseInsensitiveContains(query) ?? false)
        || album.tags.contains { $0.localizedCaseInsensitiveContains(query) }
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

#Preview {
    AlbumsView()
        .environmentObject(LoginViewModel())
}
