//
//  SignUpView.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""

    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    VStack(spacing: AppSpacing.s) {
                        Text("Create your account")
                            .font(AppFont.title)
                            .foregroundColor(AppColor.ink)
                            .multilineTextAlignment(.center)
                        Text("Start building your bite-bubble album.")
                            .font(AppFont.subheadline)
                            .foregroundColor(AppColor.inkMuted)
                    }
                    .padding(.top, 32)
                    .bounceOnAppear()

                    // Fields card
                    VStack(spacing: AppSpacing.l) {
                        AuthTextField(label: "Username", placeholder: "@yourhandle", input: $username, icon: "person.fill")
                        AuthTextField(label: "Email", placeholder: "you@example.com", input: $email, icon: "envelope.fill")
                        AuthTextField(label: "Password", placeholder: "At least 6 characters", input: $password, type: .password, icon: "lock.fill")
                        AuthTextField(label: "Confirm Password", placeholder: "Re-enter password", input: $confirmPassword, type: .password, icon: "lock.rotation")

                        if !viewModel.errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(viewModel.errorMessage)
                            }
                            .font(AppFont.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, AppSpacing.l)
                    .bounceOnAppear(delay: 0.1)

                    // Create
                    PrimaryButton(title: "Create account", icon: "sparkles", isLoading: viewModel.isLoading) {
                        Task {
                            let success = await viewModel.signUp(
                                username: username,
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                            if success {
                                Haptics.success()
                                dismiss()
                            } else {
                                Haptics.warning()
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.xxxl)
                    .bounceOnAppear(delay: 0.2)

                    // Back to login — Log in styled as a distinct pill so it's
                    // obviously tappable instead of looking like body text.
                    HStack(spacing: AppSpacing.s) {
                        Text("Have an account?")
                            .font(.clash(14, weight: .regular))
                            .foregroundColor(AppColor.inkMuted)

                        Button {
                            Haptics.tap()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.clash(15, weight: .bold))
                                Text("Log in")
                                    .font(.clash(14, weight: .semibold))
                                    .tracking(0.4)
                            }
                            .foregroundStyle(AppGradient.hero)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AppColor.primary.opacity(0.45), lineWidth: 1)
                            )
                            .shadow(color: AppColor.primary.opacity(0.18), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                        .pressableScale()
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(AppAnimation.snappy, value: viewModel.errorMessage)
    }
}

#Preview {
    SignUpView()
}
