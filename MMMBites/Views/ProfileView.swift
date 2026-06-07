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
    var profilePhotoData: Data?
    var onProfilePhotoChange: (Data?) -> Void

    @EnvironmentObject private var authViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false
    @State private var selectedPhotoData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showAddFriendSheet = false
    @State private var showManageFriendsSheet = false
    @State private var showNotificationsInfo = false
    @State private var showPrivacyInfo = false

    init(
        username: String = "Jisu",
        email: String? = nil,
        memoryCount: Int = 3,
        albumCount: Int = 3,
        friendCount: Int = 6,
        profilePhotoData: Data? = nil,
        onProfilePhotoChange: @escaping (Data?) -> Void = { _ in }
    ) {
        self.username = username
        self.email = email
        self.memoryCount = memoryCount
        self.albumCount = albumCount
        self.friendCount = friendCount
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
                                    .foregroundStyle(AppGradient.hero)
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
                                    .foregroundStyle(AppGradient.hero)
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

                        // Actions
                        VStack(spacing: AppSpacing.m) {
                            actionRow(icon: "person.badge.plus.fill",
                                      label: "Add Friend",
                                      tint: AppColor.accent) {
                                showAddFriendSheet = true
                            }
                            actionRow(icon: "person.2.fill",
                                      label: "Manage Friends",
                                      tint: AppColor.secondary) {
                                showManageFriendsSheet = true
                            }
                            actionRow(icon: "bell.fill",
                                      label: "Notifications",
                                      tint: AppColor.secondary) {
                                showNotificationsInfo = true
                            }
                            actionRow(icon: "lock.fill",
                                      label: "Privacy",
                                      tint: AppColor.primary) {
                                showPrivacyInfo = true
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
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendSheet()
                    .environmentObject(authViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showManageFriendsSheet) {
                ManageFriendsSheet()
                    .environmentObject(authViewModel)
                    .presentationDetents([.medium, .large])
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
            .sheet(isPresented: $showPrivacyInfo) {
                ComingSoonSheet(
                    title: "Privacy",
                    icon: "lock.fill",
                    message: "Album visibility and sharing controls will live here once privacy settings are wired to Firestore."
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

private struct AddFriendSheet: View {
    @EnvironmentObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showMyQRCode = false
    @State private var showQRScanner = false

    private var currentUserID: String? {
        viewModel.currentUser?.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.l) {
                    HStack(spacing: AppSpacing.m) {
                        quickActionButton(
                            icon: "qrcode",
                            title: "My QR",
                            tint: AppColor.secondary
                        ) {
                            showMyQRCode = true
                        }

                        quickActionButton(
                            icon: "qrcode.viewfinder",
                            title: "Scan QR",
                            tint: AppColor.primary
                        ) {
                            showQRScanner = true
                        }
                    }

                    HStack(spacing: AppSpacing.s) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColor.inkFaint)
                        TextField("Search username", text: $query)
                            .font(AppFont.body)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit {
                                Task { await viewModel.searchUsers(matching: query) }
                            }
                        if !query.isEmpty {
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

                    PrimaryButton(
                        title: viewModel.isSearchingFriends ? "Searching..." : "Search",
                        icon: "person.badge.plus.fill",
                        isLoading: viewModel.isSearchingFriends
                    ) {
                        Task { await viewModel.searchUsers(matching: query) }
                    }

                    if !viewModel.friendSearchMessage.isEmpty {
                        Text(viewModel.friendSearchMessage)
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ScrollView {
                        LazyVStack(spacing: AppSpacing.m) {
                            ForEach(viewModel.friendSearchResults) { user in
                                Button {
                                    Task { await viewModel.addFriend(user) }
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
                                        Image(systemName: "plus.circle.fill")
                                            .font(.clash(22, weight: .semibold))
                                            .foregroundStyle(AppGradient.hero)
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

                    Spacer(minLength: 0)
                }
                .padding(AppSpacing.xl)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            viewModel.friendSearchResults = []
            viewModel.friendSearchMessage = ""
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
                Task {
                    await viewModel.addFriend(userID: userID)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func quickActionButton(
        icon: String,
        title: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.clash(15, weight: .semibold))
                Text(title)
                    .font(AppFont.captionBold)
            }
            .foregroundColor(AppColor.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .pressableScale()
    }
}

private struct ManageFriendsSheet: View {
    @EnvironmentObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var friends: [User] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                Group {
                    if isLoading && friends.isEmpty {
                        ProgressView("Loading friends...")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.inkMuted)
                    } else if friends.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppSpacing.m) {
                                ForEach(friends) { friend in
                                    friendRow(friend)
                                }
                            }
                            .padding(AppSpacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Manage Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task(id: viewModel.currentUser?.friendIDs ?? []) {
            await loadFriends()
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "person.2")
                .font(.clash(42, weight: .light))
                .foregroundColor(AppColor.inkFaint)
            Text("No friends yet")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text("Add friends by username or QR first.")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
        }
        .padding(AppSpacing.xl)
    }

    private func friendRow(_ friend: User) -> some View {
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
                if let email = friend.email {
                    Text(email)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.inkMuted)
                }
            }

            Spacer()

            Button(role: .destructive) {
                Haptics.warning()
                Task {
                    await viewModel.removeFriend(friend)
                    friends.removeAll { $0.id == friend.id }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.clash(22, weight: .semibold))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.m)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func loadFriends() async {
        let friendIDs = viewModel.currentUser?.friendIDs ?? []
        guard !friendIDs.isEmpty else {
            friends = []
            return
        }

        isLoading = true
        defer { isLoading = false }

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

    private func avatarImage(for user: User) -> Image? {
        guard
            let base64 = user.avatarData,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
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
                            .foregroundStyle(AppGradient.hero)
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
