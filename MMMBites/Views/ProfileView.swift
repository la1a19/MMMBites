//
//  ProfileView.swift
//  MMMBites
//
//  Presented when the user taps "Profile" from the top-right menu.
//

import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins
import AVFoundation
import FirebaseFirestore

struct ProfileView: View {
    let username: String
    let email: String?
    let memoryCount: Int
    let albumCount: Int
    let friendCount: Int
    var memories: [Memory] = []
    var albums: [Album] = []
    var profilePhotoData: Data?
    var onProfilePhotoChange: (Data?) -> Void

    @EnvironmentObject private var authViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false
    @State private var selectedPhotoData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showFriendsSheet = false
    @State private var showNotificationsInfo = false
    @State private var showRecap = false
    @State private var friendNamesByID: [String: String] = [:]

    init(
        username: String = "Jisu",
        email: String? = nil,
        memoryCount: Int = 3,
        albumCount: Int = 3,
        friendCount: Int = 6,
        memories: [Memory] = [],
        albums: [Album] = [],
        profilePhotoData: Data? = nil,
        onProfilePhotoChange: @escaping (Data?) -> Void = { _ in }
    ) {
        self.username = username
        self.email = email
        self.memoryCount = memoryCount
        self.albumCount = albumCount
        self.friendCount = friendCount
        self.memories = memories
        self.albums = albums
        self.profilePhotoData = profilePhotoData
        self.onProfilePhotoChange = onProfilePhotoChange
        _selectedPhotoData = State(initialValue: profilePhotoData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Header — large avatar + username
                        VStack(spacing: AppSpacing.m) {
                            profilePhotoPicker(size: 130)
                            .scaleEffect(appear ? 1.0 : 0.85)
                            .opacity(appear ? 1 : 0)

                            VStack(spacing: 4) {
                                Text(username)
                                    .font(.clash(28, weight: .semibold))
                                    .foregroundColor(AppColor.ink)
                                if let email {
                                    Text(email)
                                        .font(.clash(14, weight: .regular))
                                        .foregroundColor(AppColor.inkMuted)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 10)
                        }
                        .padding(.top, AppSpacing.l)

                        // Middle — status card
                        VStack(spacing: AppSpacing.s) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppGradient.heroText)
                                Text("Logged in as")
                                    .foregroundColor(AppColor.inkMuted)
                                Text(username)
                                    .foregroundColor(AppColor.ink)
                                    .fontWeight(.semibold)
                            }
                            .font(.clash(15, weight: .medium))

                            // hairline
                            Rectangle()
                                .fill(AppColor.inkFaint.opacity(0.2))
                                .frame(width: 50, height: 1)
                                .padding(.vertical, 2)

                            HStack(spacing: 6) {
                                Text("You currently have")
                                    .foregroundColor(AppColor.inkMuted)
                                Text("\(memoryCount)")
                                    .font(.clash(22, weight: .bold))
                                    .foregroundStyle(AppGradient.heroText)
                                Text(memoryCount == 1 ? "memory" : "memories")
                                    .foregroundColor(AppColor.inkMuted)
                            }
                            .font(.clash(15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.xl)
                        .padding(.horizontal, AppSpacing.l)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                                .fill(AppGradient.glass)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                        .padding(.horizontal, AppSpacing.l)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 14)

                        // Stats row
                        HStack(spacing: AppSpacing.m) {
                            statTile(value: "\(albumCount)", label: "Albums",
                                     icon: "rectangle.stack.fill", tint: AppColor.secondary)
                            statTile(value: "\(memoryCount)", label: "Memories",
                                     icon: "photo.stack.fill", tint: AppColor.primary)
                            statTile(value: "\(friendCount)", label: "Friends",
                                     icon: "person.2.fill", tint: AppColor.accent)
                        }
                        .padding(.horizontal, AppSpacing.l)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 18)

                        if let highlights = ProfileHighlights(memories: memories) {
                            highlightsCard(highlights, friendNames: friendNamesByID)
                                .padding(.horizontal, AppSpacing.l)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                        }

                        // Actions
                        VStack(spacing: AppSpacing.m) {
                            actionRow(icon: "person.2.fill",
                                      label: "Friends",
                                      tint: AppColor.secondary) {
                                showFriendsSheet = true
                            }
                            actionRow(icon: "bell.fill",
                                      label: "Notifications",
                                      tint: AppColor.secondary) {
                                showNotificationsInfo = true
                            }
                            actionRow(icon: "rectangle.portrait.and.arrow.right",
                                      label: "Log out",
                                      tint: .red,
                                      destructive: true) {
                                Haptics.warning()
                                authViewModel.logout()
                                dismiss()
                            }
                        }
                        .padding(.horizontal, AppSpacing.l)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 22)

                        Spacer(minLength: AppSpacing.xl)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                withAnimation(AppAnimation.bouncy) { appear = true }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                Task { await loadProfilePhoto(from: newItem) }
            }
            .task(id: participantIDsToResolve) {
                await resolveFriendNames(for: participantIDsToResolve)
            }
            .sheet(isPresented: $showFriendsSheet) {
                FriendsSheet(memories: memories, albums: albums)
                    .environmentObject(authViewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showRecap) {
                RecapView(
                    memories: memories,
                    friendNamesByID: friendNamesByID
                )
                .environmentObject(authViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNotificationsInfo) {
                ComingSoonSheet(
                    title: "Notifications",
                    icon: "bell.fill",
                    message: "Friend reactions and shared album updates will appear here when activity tracking is added."
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Profile photo

    private func profilePhotoPicker(size: CGFloat) -> some View {
        PhotosPicker(
            selection: $photoPickerItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppGradient.hero)
                    .frame(width: size + 30, height: size + 30)
                    .blur(radius: 28)
                    .opacity(0.5)

                profilePhoto(size: size)

                Image(systemName: "camera.fill")
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppGradient.hero))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: AppColor.primary.opacity(0.35), radius: 8, y: 4)
                    .offset(x: -4, y: -4)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func profilePhoto(size: CGFloat) -> some View {
        if let selectedPhotoData,
           let image = UIImage(data: selectedPhotoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2.5))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        } else {
            AvatarView(initials: username, size: size, showRing: true)
        }
    }

    private func loadProfilePhoto(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }

        await MainActor.run {
            withAnimation(AppAnimation.snappy) {
                selectedPhotoData = data
            }
            onProfilePhotoChange(data)
            Haptics.success()
        }

        // Persist to the user doc so it survives restart AND other views
        // (which read `currentUser.avatarData`) reflect the new avatar.
        await authViewModel.updateAvatar(data)
    }

    // MARK: - Stat tile

    private func statTile(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.clash(15, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(tint.opacity(0.18)))
            Text(value)
                .font(.clash(20, weight: .bold))
                .foregroundColor(AppColor.ink)
            Text(label.uppercased())
                .font(.clash(10, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.m)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Highlights

    private var participantIDsToResolve: [String] {
        Set(memories.flatMap(\.participantIds)).sorted()
    }

    private func resolveFriendNames(for ids: [String]) async {
        let missing = ids.filter { friendNamesByID[$0] == nil }
        guard !missing.isEmpty else { return }

        let database = Firestore.firestore()
        var resolved: [String: String] = [:]
        for chunk in missing.chunked(into: 30) {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                for doc in snapshot.documents {
                    if let user = try? doc.data(as: User.self) {
                        resolved[user.id ?? doc.documentID] = user.username
                    }
                }
            } catch {
                print("[ProfileView] friend name lookup error: \(error)")
            }
        }
        await MainActor.run {
            for (id, name) in resolved {
                friendNamesByID[id] = name
            }
        }
    }

    private func highlightsCard(_ highlights: ProfileHighlights, friendNames: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("HIGHLIGHTS")
                .font(.clash(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)

            VStack(spacing: AppSpacing.s) {
                if let buddy = highlights.topBuddy {
                    let name = friendNames[buddy.userID] ?? "Friend"
                    highlightRow(
                        icon: "heart.fill",
                        tint: AppColor.primary,
                        title: "Top food buddy",
                        value: "\(name) · \(buddy.count) \(buddy.count == 1 ? "memory" : "memories")"
                    )
                }
                if let mood = highlights.topMood {
                    highlightRow(
                        icon: nil,
                        emoji: mood.mood.emoji,
                        tint: AppColor.secondary,
                        title: "Most felt",
                        value: "\(mood.mood.label) · \(mood.count) \(mood.count == 1 ? "time" : "times")"
                    )
                }
                if let reason = highlights.topReason {
                    highlightRow(
                        icon: "sparkles",
                        tint: AppColor.accent,
                        title: "Most memorable for",
                        value: "\(reason.label) · \(reason.count) \(reason.count == 1 ? "memory" : "memories")"
                    )
                }
            }

            Button {
                Haptics.tap()
                showRecap = true
            } label: {
                HStack(spacing: 6) {
                    Text("See your full recap")
                        .font(.clash(12, weight: .semibold))
                        .foregroundStyle(AppGradient.heroText)
                    Image(systemName: "arrow.right")
                        .font(.clash(11, weight: .bold))
                        .foregroundStyle(AppGradient.heroText)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .pressableScale(0.98)
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func highlightRow(
        icon: String? = nil,
        emoji: String? = nil,
        tint: Color,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: AppSpacing.m) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 36, height: 36)
                if let emoji {
                    Text(emoji).font(.system(size: 18))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.clash(14, weight: .semibold))
                        .foregroundColor(tint)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.clash(11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(AppColor.inkMuted)
                Text(value)
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Action row

    private func actionRow(icon: String,
                           label: String,
                           tint: Color,
                           destructive: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: icon)
                    .font(.clash(14, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(tint.opacity(0.18)))
                Text(label)
                    .font(.clash(15, weight: .medium))
                    .foregroundColor(destructive ? .red : AppColor.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.clash(12, weight: .semibold))
                    .foregroundColor(AppColor.inkFaint)
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, AppSpacing.m)
            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .pressableScale()
    }
}

struct FriendsSheet: View {
    let memories: [Memory]
    var albums: [Album] = []

    @EnvironmentObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var friends: [User] = []
    @State private var isLoadingFriends = false
    @State private var selectedFriend: User?
    @State private var showMyQRCode = false
    @State private var showQRScanner = false
    @State private var showCameraPermissionAlert = false

    private var currentUserID: String? { viewModel.currentUser?.id }

    private var hasSearchActivity: Bool {
        !viewModel.friendSearchResults.isEmpty ||
        (!viewModel.friendSearchMessage.isEmpty && !query.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        searchBar
                        qrChips

                        if hasSearchActivity {
                            searchResultsSection
                        }

                        if !viewModel.incomingRequests.isEmpty {
                            incomingRequestsSection
                        }

                        if !viewModel.outgoingRequests.isEmpty {
                            outgoingRequestsSection
                        }

                        yourFriendsSection
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task(id: viewModel.currentUser?.friendIDs ?? []) {
            await loadFriends()
        }
        .onDisappear {
            viewModel.friendSearchResults = []
            viewModel.friendSearchMessage = ""
        }
        .sheet(item: $selectedFriend) { friend in
            FriendMemoriesSheet(
                friend: friend,
                memories: sharedMemories(with: friend),
                albums: albums
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMyQRCode) {
            MyFriendQRCodeSheet(
                username: viewModel.currentUser?.username ?? "User",
                userID: currentUserID
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerSheet { userID in
                Task { await viewModel.sendFriendRequest(toUserID: userID) }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("Camera access needed", isPresented: $showCameraPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                openAppSettings()
            }
        } message: {
            Text("Allow camera access in Settings to scan friend QR codes.")
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColor.inkFaint)
            TextField("Find by username", text: $query)
                .font(AppFont.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.searchUsers(matching: query) }
                }
            if viewModel.isSearchingFriends {
                ProgressView().scaleEffect(0.7)
            } else if !query.isEmpty {
                Button {
                    query = ""
                    viewModel.friendSearchResults = []
                    viewModel.friendSearchMessage = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.inkFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9), in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
    }

    // MARK: - QR chips

    private var qrChips: some View {
        HStack(spacing: AppSpacing.s) {
            qrChip(icon: "qrcode", title: "My QR", tint: AppColor.secondary) {
                showMyQRCode = true
            }
            qrChip(icon: "qrcode.viewfinder", title: "Scan QR", tint: AppColor.primary) {
                requestCameraAccessForQRScan()
            }
        }
    }

    private func requestCameraAccessForQRScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showQRScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        showQRScanner = true
                    } else {
                        Haptics.warning()
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            Haptics.warning()
            showCameraPermissionAlert = true
        @unknown default:
            Haptics.warning()
            showCameraPermissionAlert = true
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func qrChip(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.clash(12, weight: .semibold))
                Text(title)
                    .font(.clash(12, weight: .semibold))
            }
            .foregroundColor(AppColor.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.86), in: Capsule(style: .continuous))
            .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .pressableScale()
    }

    // MARK: - Search results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            sectionLabel("SEARCH RESULTS")

            if !viewModel.friendSearchMessage.isEmpty {
                Text(viewModel.friendSearchMessage)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkMuted)
                    .padding(.horizontal, 4)
            }

            ForEach(viewModel.friendSearchResults) { user in
                Button {
                    Haptics.tap()
                    Task { await viewModel.sendFriendRequest(to: user) }
                } label: {
                    HStack(spacing: AppSpacing.m) {
                        AvatarView(initials: user.username, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username)
                                .font(.clash(16, weight: .semibold))
                                .foregroundColor(AppColor.ink)
                            if let email = user.email {
                                Text(email)
                                    .font(AppFont.caption)
                                    .foregroundColor(AppColor.inkMuted)
                            }
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.clash(13, weight: .bold))
                            Text("Send Request")
                                .font(.clash(11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppGradient.hero))
                    }
                    .padding(AppSpacing.m)
                    .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Friend requests

    private var incomingRequestsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            sectionLabel("FRIEND REQUESTS · \(viewModel.incomingRequests.count)")
            ForEach(viewModel.incomingRequests) { request in
                incomingRequestRow(request)
            }
        }
    }

    private func incomingRequestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: AppSpacing.m) {
            AvatarView(
                avatar: requestAvatar(from: request.fromAvatarData),
                initials: request.fromUsername,
                size: 44
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromUsername)
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text("wants to be friends")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkMuted)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Button {
                    Haptics.success()
                    Task { await viewModel.acceptFriendRequest(request) }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.clash(13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(AppGradient.hero))
                        .shadow(color: AppColor.primary.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.warning()
                    Task { await viewModel.declineFriendRequest(request) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.clash(13, weight: .bold))
                        .foregroundColor(AppColor.inkMuted)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.85)))
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.m)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var outgoingRequestsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            sectionLabel("SENT · \(viewModel.outgoingRequests.count)")
            ForEach(viewModel.outgoingRequests) { request in
                outgoingRequestRow(request)
            }
        }
    }

    private func outgoingRequestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: AppSpacing.m) {
            AvatarView(
                avatar: requestAvatar(from: request.toAvatarData),
                initials: request.toUsername,
                size: 40
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(request.toUsername)
                    .font(.clash(15, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text("Pending")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkMuted)
            }
            Spacer(minLength: 0)
            Button {
                Haptics.tap()
                Task { await viewModel.cancelFriendRequest(request) }
            } label: {
                Text("Cancel")
                    .font(.clash(11, weight: .semibold))
                    .foregroundColor(AppColor.inkMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.8)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    private func requestAvatar(from base64: String?) -> Image? {
        guard
            let base64,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    // MARK: - Your friends

    private var yourFriendsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack {
                sectionLabel("YOUR FRIENDS · \(friends.count)")
                Spacer()
                if isLoadingFriends {
                    ProgressView().scaleEffect(0.7)
                }
            }

            if friends.isEmpty {
                emptyFriendsState
            } else {
                ForEach(friends) { friend in
                    friendRow(friend)
                }
            }
        }
    }

    private var emptyFriendsState: some View {
        VStack(spacing: AppSpacing.s) {
            Image(systemName: "person.2")
                .font(.clash(28, weight: .light))
                .foregroundColor(AppColor.inkFaint)
            Text("No friends yet")
                .font(AppFont.subheadline)
                .foregroundColor(AppColor.inkMuted)
            Text("Search by username or scan a QR above.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.l)
    }

    private func friendRow(_ friend: User) -> some View {
        let shared = sharedMemoryCount(for: friend)
        return HStack(spacing: AppSpacing.s) {
            Button {
                Haptics.tap()
                selectedFriend = friend
            } label: {
                HStack(spacing: AppSpacing.m) {
                    AvatarView(
                        avatar: avatarImage(for: friend),
                        initials: friend.username,
                        size: 46,
                        showRing: true
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.username)
                            .font(.clash(16, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                        Text(shared == 0 ? "No memories yet" : "\(shared) \(shared == 1 ? "memory" : "memories") together")
                            .font(AppFont.caption)
                            .foregroundColor(shared == 0 ? AppColor.inkFaint : AppColor.inkMuted)
                    }
                    Spacer(minLength: 0)
                    if shared > 0 {
                        Image(systemName: "chevron.right")
                            .font(.clash(12, weight: .semibold))
                            .foregroundColor(AppColor.inkFaint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(shared == 0)

            Menu {
                if shared > 0 {
                    Button {
                        selectedFriend = friend
                    } label: {
                        Label("View shared memories", systemImage: "photo.stack.fill")
                    }
                }
                Button(role: .destructive) {
                    Haptics.warning()
                    Task {
                        await viewModel.removeFriend(friend)
                        friends.removeAll { $0.id == friend.id }
                    }
                } label: {
                    Label("Remove friend", systemImage: "person.fill.xmark")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.clash(15, weight: .bold))
                    .foregroundColor(AppColor.inkFaint)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(AppSpacing.m)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.clash(11, weight: .semibold))
            .tracking(1.2)
            .foregroundColor(AppColor.inkMuted)
            .padding(.leading, 4)
    }

    private func sharedMemoryCount(for friend: User) -> Int {
        sharedMemories(with: friend).count
    }

    private func sharedMemories(with friend: User) -> [Memory] {
        guard let currentUserID, let friendID = friend.id else { return [] }
        return memories.filter { memory in
            memory.includesUser(currentUserID) && memory.includesUser(friendID)
        }
    }

    private func avatarImage(for user: User) -> Image? {
        guard
            let base64 = user.avatarData,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    private func loadFriends() async {
        let friendIDs = viewModel.currentUser?.friendIDs ?? []
        guard !friendIDs.isEmpty else {
            friends = []
            return
        }

        isLoadingFriends = true
        defer { isLoadingFriends = false }

        let database = Firestore.firestore()
        var loaded: [User] = []
        for chunk in friendIDs.chunked(into: 30) {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                loaded.append(contentsOf: snapshot.documents.compactMap { document in
                    guard var user = try? document.data(as: User.self) else { return nil }
                    user.id = user.id ?? document.documentID
                    return user
                })
            } catch {
                viewModel.friendSearchMessage = error.localizedDescription
            }
        }
        friends = loaded.sorted {
            $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending
        }
    }
}

private struct ComingSoonSheet: View {
    let title: String
    let icon: String
    let message: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.l) {
                    ZStack {
                        Circle()
                            .fill(AppGradient.glass)
                            .frame(width: 96, height: 96)
                        Image(systemName: icon)
                            .font(.clash(34, weight: .semibold))
                            .foregroundStyle(AppGradient.heroText)
                    }

                    VStack(spacing: AppSpacing.s) {
                        Text(title)
                            .font(AppFont.titleSmall)
                            .foregroundColor(AppColor.ink)
                        Text(message)
                            .font(AppFont.subheadline)
                            .foregroundColor(AppColor.inkMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, AppSpacing.xl)

                    PrimaryButton(title: "Got it", icon: "checkmark") {
                        Haptics.tap()
                        dismiss()
                    }
                }
                .padding(AppSpacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MyFriendQRCodeSheet: View {
    let username: String
    let userID: String?

    @Environment(\.dismiss) private var dismiss

    private var payload: String? {
        userID.map { "mmmbites://user/\($0)" }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.l) {
                    AvatarView(initials: username, size: 72, showRing: true)

                    VStack(spacing: 4) {
                        Text(username)
                            .font(.clash(24, weight: .bold))
                            .foregroundColor(AppColor.ink)
                        Text("Scan to add friend")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.inkMuted)
                    }

                    if let payload,
                       let image = QRCodeGenerator.image(from: payload, size: 220) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 220, height: 220)
                            .padding(14)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                    } else {
                        Text("Log in to generate your QR")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.inkMuted)
                            .padding(AppSpacing.l)
                            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.l)
                .padding(.bottom, AppSpacing.xl)
            }
            .navigationTitle("My QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct QRScannerSheet: View {
    var onUserIDScanned: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var message = "Scan an MMMBites friend QR"

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.l) {
                    QRCodeScannerView { code in
                        guard let userID = FriendQRCodePayload.userID(from: code) else {
                            message = "That QR doesn't look like an MMMBites profile"
                            Haptics.warning()
                            return
                        }

                        Haptics.success()
                        onUserIDScanned(userID)
                        dismiss()
                    }
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

                    Text(message)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.xl)
            }
            .navigationTitle("Scan QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private enum FriendQRCodePayload {
    static func userID(from code: String) -> String? {
        guard let url = URL(string: code),
              url.scheme == "mmmbites",
              url.host == "user" else {
            return nil
        }

        let userID = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return userID.isEmpty ? nil : userID
    }
}

private enum QRCodeGenerator {
    private static let context = CIContext()
    private static let filter = CIFilter.qrCodeGenerator()

    static func image(from string: String, size: CGFloat) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let scale = size / outputImage.extent.width
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

private struct QRCodeScannerView: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        QRCodeScannerViewController(onCodeScanned: onCodeScanned)
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
}

private final class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didScan = false
    private let onCodeScanned: (String) -> Void

    init(onCodeScanned: @escaping (String) -> Void) {
        self.onCodeScanned = onCodeScanned
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didScan = false
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didScan,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else {
            return
        }

        didScan = true
        onCodeScanned(code)
    }
}

// MARK: - Profile highlights

private struct ProfileHighlights {
    struct BuddyStat: Hashable { let userID: String; let count: Int }
    struct MoodStat: Hashable { let mood: MemoryMood; let count: Int }
    struct ReasonStat: Hashable { let label: String; let count: Int }

    let topBuddy: BuddyStat?
    let topMood: MoodStat?
    let topReason: ReasonStat?

    init?(memories: [Memory]) {
        guard !memories.isEmpty else { return nil }

        var buddyCounts: [String: Int] = [:]
        var moodCounts: [MemoryMood: Int] = [:]
        var reasonCounts: [String: Int] = [:]

        for memory in memories {
            for id in memory.participantIds {
                buddyCounts[id, default: 0] += 1
            }
            if let mood = memory.mood {
                moodCounts[mood, default: 0] += 1
            }
            for tag in memory.memorableTags {
                let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                reasonCounts[trimmed.lowercased(), default: 0] += 1
            }
        }

        let topBuddyEntry = buddyCounts.max { $0.value < $1.value }
        let topMoodEntry = moodCounts.max { $0.value < $1.value }
        let topReasonEntry = reasonCounts.max { $0.value < $1.value }

        let buddy = topBuddyEntry.map { BuddyStat(userID: $0.key, count: $0.value) }
        let mood = topMoodEntry.map { MoodStat(mood: $0.key, count: $0.value) }
        let reason = topReasonEntry.map { ReasonStat(label: $0.key.capitalized, count: $0.value) }

        if buddy == nil && mood == nil && reason == nil { return nil }

        self.topBuddy = buddy
        self.topMood = mood
        self.topReason = reason
    }
}

// MARK: - Friend memories sheet

private struct FriendMemoriesSheet: View {
    let friend: User
    let memories: [Memory]
    var albums: [Album] = []

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.s),
        GridItem(.flexible(), spacing: AppSpacing.s),
        GridItem(.flexible(), spacing: AppSpacing.s)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(spacing: AppSpacing.l) {
                        header

                        if memories.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: AppSpacing.s) {
                                ForEach(memories) { memory in
                                    memoryCell(memory)
                                }
                            }
                            .padding(.horizontal, AppSpacing.l)
                        }
                    }
                    .padding(.vertical, AppSpacing.l)
                }
            }
            .navigationTitle(friend.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: AppSpacing.s) {
            AvatarView(initials: friend.username, size: 64, showRing: true)
            VStack(spacing: 2) {
                Text("\(memories.count) \(memories.count == 1 ? "memory" : "memories") together")
                    .font(.clash(16, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                if let recent = memories.first {
                    Text("Latest: \(recent.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.inkMuted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.l)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.s) {
            Image(systemName: "fork.knife")
                .font(.clash(36, weight: .light))
                .foregroundColor(AppColor.inkFaint)
            Text("No memories together yet")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text("Tag \(friend.username) on a meal memory to start.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
    }

    private func memoryCell(_ memory: Memory) -> some View {
        let parentAlbum = albums.first { $0.id == memory.albumId }
        return NavigationLink {
            MemoryDetailView(
                memory: memory,
                albumTitle: parentAlbum?.title ?? "Memory",
                album: parentAlbum
            )
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                MemoryPhotoThumbnail(
                    photoData: memory.photoData,
                    imageURLs: memory.imageURLs,
                    width: 108,
                    height: 108,
                    isCircle: false
                )
                .frame(maxWidth: .infinity)

                Text(memory.title)
                    .font(.clash(12, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.clash(10, weight: .medium))
                    .foregroundColor(AppColor.inkFaint)
            }
            .padding(8)
            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .pressableScale()
    }
}

#Preview {
    ProfileView(
        username: "Jisu",
        email: "jisu@mmmbites.app",
        memoryCount: 12,
        albumCount: 3,
        friendCount: 6
    )
    .environmentObject(LoginViewModel())
}
