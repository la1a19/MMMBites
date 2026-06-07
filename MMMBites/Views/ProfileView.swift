//
//  ProfileView.swift
//  MMMBites
//
//  Presented when the user taps "Profile" from the top-right menu.
//

import SwiftUI
import PhotosUI

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
                            actionRow(icon: "bell.fill",
                                      label: "Notifications",
                                      tint: AppColor.secondary) {
                                // notifications later
                            }
                            actionRow(icon: "lock.fill",
                                      label: "Privacy",
                                      tint: AppColor.primary) {
                                // privacy later
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
                            .background(AppGradient.glass, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
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

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.l) {
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
