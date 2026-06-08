//
//  AlbumsView.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var authViewModel: LoginViewModel

    // Mock data for now. Replace with data from a ViewModel + Firestore later.
    @Binding var albums: [Album]
    @Binding var albumMemories: [String: [Memory]]
    
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedTags: Set<String> = []
    @State private var showAddAlbum = false
    @State private var currentPage = 0
    @State private var carouselDragOffset: CGFloat = 0
    @State private var showGridView = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showMemoryBoard = false
    @State private var profilePhotoData: Data?

    
    //This lets AlbumsView receive shared data from MainAlbumsContainerView, while still keeping preview compatibility.
    init(
        albums: Binding<[Album]> = .constant(MockData.allAlbums),
        albumMemories: Binding<[String: [Memory]]> = .constant(
            Dictionary(
                uniqueKeysWithValues: MockData.allAlbums.map { album in
                    (album.id, MockData.memories(forAlbumId: album.id))
                }
            )
        )
    ) {
        self._albums = albums
        self._albumMemories = albumMemories
    }
    
    // All filter options shown when the filter panel is open
    private let filterOptions = ["Picnic", "Friends", "Cozy", "Dinner", "Spicy", "Special"]

    // Albums after applying selected tag filters + search text
    private var filteredAlbums: [Album] {
        albums.filter { album in
            let albumTags = Set(album.tags.map { $0.capitalized })

            let matchesTags =
                selectedTags.isEmpty ||
                !selectedTags.isDisjoint(with: albumTags)

            let matchesSearch =
                searchText.isEmpty ||
                album.title.localizedCaseInsensitiveContains(searchText) ||
                album.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                }

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

                    SearchFilterBar(
                        searchText: $searchText,
                        showFilters: $showFilters
                    )
                    .bounceOnAppear(delay: 0.1)

                    sectionHeader
                        .bounceOnAppear(delay: 0.15)

                    bubblesCarousel
                        .bounceOnAppear(delay: 0.2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.s)

                if showFilters {
                    filterDropdownOverlay
                        .transition(.opacity)
                        .zIndex(20)
                }
            }
            .animation(AppAnimation.snappy, value: showFilters)
            .fullScreenCover(isPresented: $showMemoryBoard) {
                NavigationStack {
                    UnlimitedMemoryBoardView(
                        albums: albums,
                        albumMemories: $albumMemories,
                        showUnlimitedBoard: $showMemoryBoard
                    )
                }
            }
            .onChange(of: searchText) { _, _ in
                currentPage = safeCurrentPage(for: filteredAlbums)
            }
            .onChange(of: selectedTags) { _, _ in
                currentPage = safeCurrentPage(for: filteredAlbums)
            }
            .sheet(isPresented: $showAddAlbum) {
                NavigationStack {
                    AddAlbumView { album in
                        withAnimation(AppAnimation.snappy) {
                            albums.insert(album, at: 0)
                            albumMemories[album.id] = []
                            currentPage = 0
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(
                    username: currentUsername,
                    email: currentUserEmail,
                    memoryCount: albumMemories.values.reduce(0) { $0 + $1.count },
                    albumCount: albums.count,
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
        HStack {
            Button {
                Haptics.tap()
                showMemoryBoard = true
            } label: {
                Image(systemName: "rectangle.3.group.bubble.left.fill")
                    .font(.clash(18, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 42, height: 42)
                    .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
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
                HStack(spacing: 8) {
                    profileAvatar(size: 32)
                    Text(currentUsername)
                        .font(AppFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.ink)
                    Image(systemName: "chevron.down")
                        .font(.clash(11, weight: .bold))
                        .foregroundColor(AppColor.inkMuted)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppGradient.glass, in: Capsule(style: .continuous))
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
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
    private var filterDropdownOverlay: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(AppAnimation.snappy) {
                        showFilters = false
                    }
                }

            filterDropdownMenu
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, 210)
        }
    }
    private var filterDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filter by tags")
                    .font(.clash(15, weight: .semibold))
                    .foregroundColor(AppColor.ink)

                Spacer()

                Button {
                    Haptics.tap()
                    withAnimation(AppAnimation.snappy) {
                        showFilters = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColor.inkMuted)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 10
                ) {
                    ForEach(filterOptions, id: \.self) { tag in
                        Button {
                            Haptics.selection()
                            withAnimation(AppAnimation.snappy) {
                                toggleTag(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)

                                if selectedTags.contains(tag) {
                                    Spacer()

                                    Image(systemName: "checkmark")
                                        .font(.clash(13, weight: .bold))
                                }
                            }
                            .font(AppFont.subheadline)
                            .foregroundColor(selectedTags.contains(tag) ? .white : AppColor.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Capsule().fill(
                                    selectedTags.contains(tag)
                                    ? AppColor.tag(tag)
                                    : Color.white.opacity(0.72)
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 190)

            if !selectedTags.isEmpty {
                Button {
                    Haptics.tap()
                    withAnimation(AppAnimation.snappy) {
                        selectedTags.removeAll()
                    }
                } label: {
                    Text("Clear selected filters")
                        .font(AppFont.captionBold)
                        .foregroundColor(AppColor.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.5), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
 
    // MARK: - Title

    private var titleRow: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your")
                    .font(.clash(30, weight: .semibold))
                    .foregroundColor(AppColor.inkMuted)

                Text("Albums")
                    .font(.clash(40, weight: .black))
                    .foregroundStyle(AppGradient.hero)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()

                GlassAddButton {
                    Haptics.soft()
                    showAddAlbum = true
                }

                Spacer()
            }
            .frame(width: 110)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .center)
        .padding(.horizontal, 12)
    }
    // MARK: - Search + filter
    private var searchRow: some View {

        HStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColor.inkFaint)
                TextField("Search tag", text: $searchText)
                    .font(AppFont.body)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.9), in: Capsule(style: .continuous))

            Button {
                Haptics.tap()
                withAnimation(AppAnimation.snappy) { showFilters.toggle() }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(showFilters ? .white : AppColor.ink)
                    .padding(12)
                    .background(
                        Circle().fill(showFilters ? AppColor.primary : Color.clear)
                    )
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
        .background(Color.white.opacity(0.55), in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .animation(AppAnimation.snappy, value: searchText.isEmpty)
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(alignment: .center) {
            Text("Your Bite Bubbles")
                .font(.clash(24, weight: .bold))
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
            if filteredAlbums.isEmpty {
                emptyState
            } else if showGridView {
                gridView
            } else {
                carouselView
            }
        }
    }

    private var carouselView: some View {
        VStack(spacing: AppSpacing.l) {
            customAlbumCarousel
                .frame(height: 360)

            albumCarouselScrollbar
                .padding(.horizontal, 70)

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
    
    private var customAlbumCarousel: some View {
        GeometryReader { proxy in
            let albums = filteredAlbums
            let currentIndex = safeCurrentPage(for: albums)
            let previousIndex = wrappedIndex(currentIndex - 1, count: albums.count)
            let nextIndex = wrappedIndex(currentIndex + 1, count: albums.count)

            let sideOffset = proxy.size.width * 0.62
            let dragProgress = carouselDragOffset / proxy.size.width

            ZStack {
                if albums.count > 1 {
                    albumCarouselBubble(
                        albums[previousIndex],
                        isActive: false,
                        size: 190
                    )
                    .offset(
                        x: -sideOffset + carouselDragOffset,
                        y: 12
                    )
                    .opacity(0.34 + max(0, dragProgress) * 0.35)
                    .scaleEffect(0.78 + max(0, dragProgress) * 0.16)
                    .zIndex(carouselDragOffset > 0 ? 2 : 1)

                    albumCarouselBubble(
                        albums[nextIndex],
                        isActive: false,
                        size: 190
                    )
                    .offset(
                        x: sideOffset + carouselDragOffset,
                        y: 12
                    )
                    .opacity(0.34 + max(0, -dragProgress) * 0.35)
                    .scaleEffect(0.78 + max(0, -dragProgress) * 0.16)
                    .zIndex(carouselDragOffset < 0 ? 2 : 1)
                }

                NavigationLink {
                    AlbumDetailView(
                        album: albums[currentIndex],
                        initialMemories: memories(for: albums[currentIndex])
                    ) { updatedMemories in
                        albumMemories[albums[currentIndex].id] = updatedMemories
                    } onAlbumUpdate: { updatedAlbum in
                        updateAlbum(updatedAlbum)
                    }
                } label: {
                    albumCarouselBubble(
                        albums[currentIndex],
                        isActive: true,
                        size: 280
                    )
                }
                .buttonStyle(.plain)
                .offset(x: carouselDragOffset)
                .scaleEffect(1.0 - min(abs(dragProgress) * 0.12, 0.12))
                .zIndex(3)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        carouselDragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 65

                        if value.translation.width < -threshold {
                            moveCarouselForward()
                        } else if value.translation.width > threshold {
                            moveCarouselBackward()
                        }

                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            carouselDragOffset = 0
                        }
                    }
            )
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: carouselDragOffset)
        }
    }
    
    private func albumCarouselBubble(
        _ album: Album,
        isActive: Bool,
        size: CGFloat
    ) -> some View {
        ZStack {
            Circle()
                .fill(AppGradient.hero)
                .frame(width: size + 54, height: size + 54)
                .blur(radius: isActive ? 18 : 10)
                .opacity(isActive ? 0.19 : 0.09)

            MemoryPhotoThumbnail(
                photoData: coverPhotoData(for: album),
                imageURLs: coverImageURLs(for: album),
                width: size,
                height: size,
                placeholderSystemImage: "photo.on.rectangle.angled"
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isActive ? 0.9 : 0.55), lineWidth: isActive ? 3 : 2)
            )
            .shadow(
                color: .black.opacity(isActive ? 0.18 : 0.08),
                radius: isActive ? 20 : 10,
                y: isActive ? 12 : 6
            )

            if isActive {
                VStack {
                    Spacer()

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
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                    .padding(.bottom, 14)
                }
                .frame(width: size, height: size)
            }
        }
        .frame(width: size + 110, height: size + 110)
    }
    
    private var albumCarouselScrollbar: some View {
        GeometryReader { proxy in
            let count = max(filteredAlbums.count, 1)
            let progress = CGFloat(safeCurrentPage(for: filteredAlbums)) / CGFloat(max(count - 1, 1))

            let trackWidth = proxy.size.width
            let minThumbWidth: CGFloat = 36
            let thumbWidth = max(trackWidth / CGFloat(count), minThumbWidth)
            let travelWidth = max(trackWidth - thumbWidth, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(height: 6)

                Capsule()
                    .fill(AppGradient.hero)
                    .frame(width: thumbWidth, height: 6)
                    .offset(x: travelWidth * progress)
                    .shadow(color: AppColor.primary.opacity(0.25), radius: 5, y: 2)
            }
        }
        .frame(height: 8)
    }

    private var currentAlbum: Album? {
        guard !filteredAlbums.isEmpty else { return nil }
        return filteredAlbums[safeCurrentPage(for: filteredAlbums)]
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.l) {
                ForEach(filteredAlbums) { album in
                    NavigationLink {
                        AlbumDetailView(
                            album: album,
                            initialMemories: memories(for: album)
                        ) { updatedMemories in
                            albumMemories[album.id] = updatedMemories
                        } onAlbumUpdate: { updatedAlbum in
                            updateAlbum(updatedAlbum)
                        }
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
                .tracking(2)
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

            // OPEN ALBUM pill
            VStack {
                Spacer()
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
                .padding(.bottom, 14)
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

    // Frame 2 — separate info card (title + tags) shown below the photo
    private func albumInfoCard(_ album: Album) -> some View {
        VStack(spacing: AppSpacing.m) {
            Text(album.title)
                .font(.clash(26, weight: .medium))
                .tracking(4)
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
            ZStack {
                Circle()
                    .fill(AppGradient.glass)
                    .frame(width: 140, height: 140)
                Image(systemName: "tray")
                    .font(.clash(48, weight: .light))
                    .foregroundColor(AppColor.inkFaint)
            }
            Text("No albums match your filters")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text("Try clearing tags or a different search.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
            Button {
                withAnimation(AppAnimation.snappy) {
                    selectedTags.removeAll()
                    searchText = ""
                }
                Haptics.tap()
            } label: {
                Text("Reset filters")
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
        .frame(height: 500)
    }

    // MARK: - Helpers

    private func safeCurrentPage(for albums: [Album]) -> Int {
        guard !albums.isEmpty else { return 0 }
        return min(max(currentPage, 0), albums.count - 1)
    }

    private func wrappedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }

        if index < 0 {
            return count - 1
        }

        if index >= count {
            return 0
        }

        return index
    }

    private func moveCarouselForward() {
        guard !filteredAlbums.isEmpty else { return }

        Haptics.selection()

        withAnimation(AppAnimation.smooth) {
            currentPage = wrappedIndex(currentPage + 1, count: filteredAlbums.count)
        }
    }

    private func moveCarouselBackward() {
        guard !filteredAlbums.isEmpty else { return }

        Haptics.selection()

        withAnimation(AppAnimation.smooth) {
            currentPage = wrappedIndex(currentPage - 1, count: filteredAlbums.count)
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func memories(for album: Album) -> [Memory] {
        albumMemories[album.id] ?? []
    }

    private func coverPhotoData(for album: Album) -> [Data] {
        if let coverPhotoData = album.coverPhotoData {
            return [coverPhotoData]
        }

        return memories(for: album).first { !$0.photoData.isEmpty }?.photoData ?? []
    }

    private func coverImageURLs(for album: Album) -> [String] {
        if let coverImageURL = album.coverImageURL {
            return [coverImageURL]
        }

        if let memoryURLs = memories(for: album).first(where: { !$0.imageURLs.isEmpty })?.imageURLs {
            return memoryURLs
        }

        return []
    }

    private func updateAlbum(_ updatedAlbum: Album) {
        withAnimation(AppAnimation.snappy) {
            if let index = albums.firstIndex(where: { $0.id == updatedAlbum.id }) {
                albums[index] = updatedAlbum
            }
        }
    }
}

#Preview {
    AlbumsView()
        .environmentObject(LoginViewModel())
}
