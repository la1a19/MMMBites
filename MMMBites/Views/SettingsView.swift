//
//  SettingsView.swift
//  MMMBites
//
//  Presented from the top-right user menu → "Settings".
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var authViewModel: LoginViewModel

    // App Store Connect uses this hosted privacy policy URL for review metadata.
    private let privacyPolicyURL = URL(string: "https://jisukimit-gif.github.io/mmmbites-legal/PRIVACY_POLICY")!

    // Persisted preferences
    @AppStorage("pref.hapticFeedback")      private var hapticFeedback: Bool = true
    @AppStorage("pref.memoryReminders")     private var memoryReminders: Bool = true

    @State private var showFeedbackSheet = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showChangePasswordSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        preferencesSection
                            .bounceOnAppear()

                        aboutSection
                            .bounceOnAppear(delay: 0.1)

                        accountSection
                            .bounceOnAppear(delay: 0.15)

                        Text("MMMBites · \(appVersion)")
                            .font(.clash(11, weight: .medium))
                            .foregroundColor(AppColor.inkFaint)
                            .padding(.top, AppSpacing.s)
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Settings")
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
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView(webURL: privacyPolicyURL)
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showChangePasswordSheet) {
                ChangePasswordSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Delete account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This permanently removes your profile, albums, memories, and friend connections. This action cannot be undone.")
            }
            .alert(
                "Couldn't delete account",
                isPresented: Binding(
                    get: { deleteErrorMessage != nil },
                    set: { if !$0 { deleteErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { deleteErrorMessage = nil }
            } message: {
                Text(deleteErrorMessage ?? "")
            }
        }
    }

    // MARK: - PREFERENCES

    private var preferencesSection: some View {
        sectionGroup(title: "PREFERENCES") {
            toggleRow(icon: "iphone.radiowaves.left.and.right",
                      tint: AppColor.primary,
                      title: "Haptic feedback",
                      subtitle: nil,
                      isOn: $hapticFeedback)

            divider

            toggleRow(icon: "bell.fill",
                      tint: AppColor.secondary,
                      title: "Memory reminders",
                      subtitle: nil,
                      isOn: $memoryReminders)
        }
    }

    // MARK: - ABOUT

    private var aboutSection: some View {
        sectionGroup(title: "ABOUT") {
            navRow(icon: "envelope.fill",
                   tint: AppColor.primary,
                   title: "Send feedback",
                   action: {
                       Haptics.tap()
                       showFeedbackSheet = true
                   })
            divider
            navRow(icon: "lock.shield.fill",
                   tint: AppColor.secondary,
                   title: "Privacy policy",
                   action: {
                       Haptics.tap()
                       showPrivacyPolicy = true
                   })
            divider
            navRow(icon: "doc.text.fill",
                   tint: AppColor.accent,
                   title: "Terms of service",
                   action: {
                       Haptics.tap()
                       showTermsOfService = true
                   })
        }
    }

    // MARK: - ACCOUNT (delete)

    private var accountSection: some View {
        sectionGroup(title: "ACCOUNT") {
            navRow(icon: "key.fill",
                   tint: AppColor.primary,
                   title: "Change password",
                   action: {
                       Haptics.tap()
                       showChangePasswordSheet = true
                   })

            divider

            Button {
                Haptics.warning()
                showDeleteConfirm = true
            } label: {
                HStack(spacing: AppSpacing.m) {
                    iconBadge(icon: "trash.fill", tint: .red)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Delete account")
                            .font(.clash(15, weight: .medium))
                            .foregroundColor(.red)
                        Text("Permanently remove your data")
                            .font(.clash(12, weight: .regular))
                            .foregroundColor(AppColor.inkFaint)
                    }
                    Spacer()
                    if isDeletingAccount {
                        ProgressView()
                    }
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount)
        }
    }

    private func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        let uid = user.uid
        let database = Firestore.firestore()

        do {
            try await revokeAppleTokenIfNeeded(for: user)

            // Albums owned by the user (memories under each are unowned-cascade
            // dropped here too).
            let albumsSnap = try await database.collection("albums")
                .whereField("ownerId", isEqualTo: uid)
                .getDocuments()
            for doc in albumsSnap.documents {
                let albumID = doc.documentID
                await PhotoStorage.deleteAlbumCover(albumID: albumID)
                LocalPhotoCache.clearAlbumCover(albumID: albumID)
                try await doc.reference.delete()
            }

            // Memories captured by the user (in case any exist outside their
            // own albums).
            let memoriesSnap = try await database.collection("memories")
                .whereField("capturedById", isEqualTo: uid)
                .getDocuments()
            for doc in memoriesSnap.documents {
                let memoryID = doc.documentID
                await PhotoStorage.deleteMemoryPhotos(memoryID: memoryID)
                LocalPhotoCache.clearMemoryPhotos(memoryID: memoryID)
                try await doc.reference.delete()
            }

            // Friend requests where this user is either side.
            let outgoingSnap = try await database.collection("friendRequests")
                .whereField("fromUserId", isEqualTo: uid)
                .getDocuments()
            for doc in outgoingSnap.documents {
                try await doc.reference.delete()
            }
            let incomingSnap = try await database.collection("friendRequests")
                .whereField("toUserId", isEqualTo: uid)
                .getDocuments()
            for doc in incomingSnap.documents {
                try await doc.reference.delete()
            }

            // User profile doc.
            try await database.collection("users").document(uid).delete()

            // Finally tear down the Firebase Auth account.
            try await user.delete()

            // Auth state listener in LoginViewModel will return us to login.
            await MainActor.run { dismiss() }
        } catch let error as NSError {
            await MainActor.run {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    deleteErrorMessage = "For security, please sign out and sign back in within the last few minutes, then try deleting again."
                } else {
                    deleteErrorMessage = "Could not finish deleting your account: \(error.localizedDescription)"
                }
            }
        }
    }

    private func revokeAppleTokenIfNeeded(for user: FirebaseAuth.User) async throws {
        let usesAppleSignIn = user.providerData.contains { provider in
            provider.providerID == "apple.com"
        }
        guard usesAppleSignIn else { return }

        let credential = try await AppleAccountDeletionAuthorizer().credential()
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: credential.identityToken,
            rawNonce: credential.rawNonce,
            fullName: nil
        )
        try await user.reauthenticate(with: firebaseCredential)
        try await Auth.auth().revokeToken(withAuthorizationCode: credential.authorizationCode)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func sectionGroup<Content: View>(title: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.clash(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, AppSpacing.s)
            .background(AppGradient.glass,
                        in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.inkFaint.opacity(0.15))
            .frame(height: 1)
            .padding(.leading, 50)
    }

    private func iconBadge(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.clash(13, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 32, height: 32)
            .background(Circle().fill(tint.opacity(0.18)))
    }

    private func toggleRow(icon: String,
                           tint: Color,
                           title: String,
                           subtitle: String?,
                           isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.m) {
            iconBadge(icon: icon, tint: tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.clash(15, weight: .medium))
                    .foregroundColor(AppColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.clash(12, weight: .regular))
                        .foregroundColor(AppColor.inkFaint)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColor.primary)
                .onChange(of: isOn.wrappedValue) { _, _ in
                    Haptics.selection()
                }
        }
        .padding(.vertical, 10)
    }

    private func navRow(icon: String,
                        tint: Color,
                        title: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.m) {
                iconBadge(icon: icon, tint: tint)
                Text(title)
                    .font(.clash(15, weight: .medium))
                    .foregroundColor(AppColor.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.clash(12, weight: .semibold))
                    .foregroundColor(AppColor.inkFaint)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

private struct AppleDeletionCredential {
    let identityToken: String
    let authorizationCode: String
    let rawNonce: String
}

@MainActor
private final class AppleAccountDeletionAuthorizer: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleDeletionCredential, Error>?
    private var rawNonce: String?

    func credential() async throws -> AppleDeletionCredential {
        try await withCheckedThrowingContinuation { continuation in
            let rawNonce = Self.makeNonce()
            self.rawNonce = rawNonce
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = []
            request.nonce = Self.sha256(rawNonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let authorizationCodeData = appleCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8),
              let rawNonce else {
            finish(with: AuthError.missingAppleCredential)
            return
        }

        finish(with: AppleDeletionCredential(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            rawNonce: rawNonce
        ))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        finish(with: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    private func finish(with credential: AppleDeletionCredential) {
        continuation?.resume(returning: credential)
        continuation = nil
        rawNonce = nil
    }

    private func finish(with error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        rawNonce = nil
    }

    private static func makeNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var remaining = length
        var result = ""

        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status == errSecSuccess, random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private enum AuthError: LocalizedError {
        case missingAppleCredential

        var errorDescription: String? {
            "Couldn't read Apple credentials."
        }
    }
}

// MARK: - Privacy policy

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let webURL: URL

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MMMBites Privacy Policy")
                                .font(.clash(24, weight: .bold))
                                .foregroundColor(AppColor.ink)
                            Text("Effective date: June 10, 2026")
                                .font(.clash(13, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                            Text("MMMBites is a meal-memory journal that lets you save photos, locations, moods, and notes about meals you eat and share them with friends you choose.")
                                .font(.clash(14, weight: .regular))
                                .foregroundColor(AppColor.ink)
                                .lineSpacing(4)
                                .padding(.top, 4)
                        }
                        .padding(AppSpacing.l)
                        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )

                        policySection(
                            title: "Information we collect",
                            items: [
                                "Account information: email address, username, and optional profile photo.",
                                "Content you create: photos, albums, tags, memory details, notes, place names, and selected coordinates.",
                                "Friend connections, QR-code friend actions, username search, and reactions on shared memories.",
                                "Camera and photo library access only when you trigger features that need them."
                            ]
                        )

                        policySection(
                            title: "What we do not collect",
                            items: [
                                "We do not access precise GPS location automatically.",
                                "We do not collect contacts, calendars, microphone, or health data.",
                                "We do not run cross-app tracking analytics, show ads, sell data, or rent data."
                            ]
                        )

                        policySection(
                            title: "How we use your information",
                            items: [
                                "To authenticate you and keep you signed in.",
                                "To save and display your albums, memories, photos, and profile.",
                                "To show shared memories only to friends you explicitly tag or share with.",
                                "To generate in-app highlights and recaps from your own content."
                            ]
                        )

                        policySection(
                            title: "Third-party services",
                            items: [
                                "MMMBites uses Firebase Authentication for email/password login.",
                                "Cloud Firestore stores profiles, albums, memories, friend connections, and reactions.",
                                "Firebase Storage stores photo files attached to memories and profiles.",
                                "Google's privacy policy is available at https://policies.google.com/privacy."
                            ]
                        )

                        policySection(
                            title: "Sharing and retention",
                            items: [
                                "A memory or album is private until you tag a friend or set it as shared.",
                                "Removing a tag revokes that friend's access.",
                                "We keep your data for as long as your account exists."
                            ]
                        )

                        policySection(
                            title: "Your rights",
                            items: [
                                "You can view and edit memories, albums, profile fields, and friend connections inside the app.",
                                "You can delete individual memories or albums from the relevant detail screen.",
                                "You can delete your account from Settings. This permanently removes your profile, albums, memories, friend requests, and sign-in credentials.",
                                "For legal requests such as export or correction, contact lemonmint28@gmail.com."
                            ]
                        )

                        policySection(
                            title: "Children, security, and changes",
                            items: [
                                "MMMBites is not directed to children under 13.",
                                "Traffic between the app and Firebase uses HTTPS/TLS, and passwords are managed by Firebase Authentication.",
                                "If this policy changes materially, we will update the effective date and notify you in-app or by email."
                            ]
                        )

                        Button {
                            Haptics.tap()
                            openURL(webURL)
                        } label: {
                            HStack {
                                Image(systemName: "safari.fill")
                                Text("Open web version")
                            }
                            .font(.clash(14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppColor.primary, in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Privacy")
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
        }
    }

    private func policySection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.clash(17, weight: .semibold))
                .foregroundColor(AppColor.ink)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(AppColor.primary.opacity(0.75))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.clash(13, weight: .regular))
                            .foregroundColor(AppColor.inkMuted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }
}

// MARK: - Terms of service

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MMMBites Terms")
                                .font(.clash(24, weight: .bold))
                                .foregroundColor(AppColor.ink)
                            Text("Effective date: June 10, 2026")
                                .font(.clash(13, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                            Text("By using MMMBites, you agree to use the app respectfully and only upload content you have the right to save or share.")
                                .font(.clash(14, weight: .regular))
                                .foregroundColor(AppColor.ink)
                                .lineSpacing(4)
                                .padding(.top, 4)
                        }
                        .padding(AppSpacing.l)
                        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )

                        termsSection(
                            title: "Your account",
                            items: [
                                "Use accurate account information and keep your sign-in credentials secure.",
                                "You are responsible for activity that happens through your account.",
                                "You can delete your account from Settings."
                            ]
                        )

                        termsSection(
                            title: "Your content",
                            items: [
                                "You own the meal memories, photos, notes, and albums you create.",
                                "Only upload content you have permission to use.",
                                "When you tag or share with friends, those friends can view the shared memory or album."
                            ]
                        )

                        termsSection(
                            title: "Acceptable use",
                            items: [
                                "Do not upload illegal, harmful, abusive, or privacy-invading content.",
                                "Do not attempt to access another person's account or data.",
                                "Do not interfere with the app, Firebase services, or other users' experience."
                            ]
                        )

                        termsSection(
                            title: "Service changes",
                            items: [
                                "MMMBites is provided as a student project and may change, pause, or stop features over time.",
                                "We may update these terms by changing the effective date and notifying users when appropriate.",
                                "Questions about these terms can be sent to lemonmint28@gmail.com."
                            ]
                        )
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Terms")
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
        }
    }

    private func termsSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.clash(17, weight: .semibold))
                .foregroundColor(AppColor.ink)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(AppColor.accent.opacity(0.75))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.clash(13, weight: .regular))
                            .foregroundColor(AppColor.inkMuted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }
}

// MARK: - Change password

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isSaving = false

    private var canSubmit: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        confirmPassword.count >= 6 &&
        !isSaving
    }

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)

            ScrollView {
                VStack(spacing: AppSpacing.l) {
                    VStack(spacing: 4) {
                        Text("Change password")
                            .font(.clash(22, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                        Text("Enter your current password before choosing a new one.")
                            .font(.clash(13, weight: .regular))
                            .foregroundColor(AppColor.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.l)

                    VStack(spacing: AppSpacing.m) {
                        AuthTextField(
                            label: "Current password",
                            placeholder: "Current password",
                            input: $currentPassword,
                            type: .password,
                            icon: "lock.fill"
                        )

                        AuthTextField(
                            label: "New password",
                            placeholder: "At least 6 characters",
                            input: $newPassword,
                            type: .password,
                            icon: "key.fill"
                        )

                        AuthTextField(
                            label: "Confirm new password",
                            placeholder: "Repeat new password",
                            input: $confirmPassword,
                            type: .password,
                            icon: "checkmark.shield.fill"
                        )
                    }

                    if let errorMessage {
                        messagePill(text: errorMessage, color: .red, icon: "exclamationmark.triangle.fill")
                    }

                    if let successMessage {
                        messagePill(text: successMessage, color: .green, icon: "checkmark.circle.fill")
                    }

                    PrimaryButton(title: "Update password", icon: "checkmark", isLoading: isSaving) {
                        Task { await updatePassword() }
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.55)

                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.clash(14, weight: .semibold))
                            .foregroundColor(AppColor.inkMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Spacer(minLength: AppSpacing.l)
                }
                .padding(AppSpacing.xl)
            }
        }
    }

    private func updatePassword() async {
        errorMessage = nil
        successMessage = nil

        guard newPassword == confirmPassword else {
            Haptics.warning()
            errorMessage = "New passwords do not match."
            return
        }

        guard newPassword.count >= 6 else {
            Haptics.warning()
            errorMessage = "New password must be at least 6 characters."
            return
        }

        guard let user = Auth.auth().currentUser, let email = user.email else {
            Haptics.warning()
            errorMessage = "No email/password account is currently signed in."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            Haptics.success()
            successMessage = "Password updated."
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch let error as NSError {
            Haptics.warning()
            errorMessage = readableAuthError(error)
        }
    }

    private func readableAuthError(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "Current password is incorrect."
        case AuthErrorCode.weakPassword.rawValue:
            return "New password is too weak. Use at least 6 characters."
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "Please sign out, sign back in, and try again."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection and try again."
        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled."
        default:
            return error.localizedDescription
        }
    }

    private func messagePill(text: String, color: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.clash(13, weight: .semibold))
            Text(text)
                .font(.clash(13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
    }
}

// MARK: - Feedback sheet

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message: String = ""

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)
            VStack(spacing: AppSpacing.l) {
                VStack(spacing: 4) {
                    Text("Send feedback")
                        .font(.clash(20, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Text("We read every note 🍳")
                        .font(.clash(13, weight: .regular))
                        .foregroundColor(AppColor.inkMuted)
                }
                .padding(.top, AppSpacing.l)

                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("What's on your mind?")
                            .font(.clash(15))
                            .foregroundColor(AppColor.inkFaint)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $message)
                        .font(.clash(15))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .frame(minHeight: 120)
                }
                .background(Color.white.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )

                PrimaryButton(title: "Send", icon: "paperplane.fill") {
                    Haptics.success()
                    dismiss()
                }
                Spacer()
            }
            .padding(AppSpacing.xl)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LoginViewModel())
}
