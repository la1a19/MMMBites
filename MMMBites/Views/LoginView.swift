//
//  LoginView.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var rememberPassword = false
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel: LoginViewModel
    @State private var showSignUp = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    VStack(spacing: AppSpacing.s) {
                        Text("Welcome back")
                            .font(AppFont.display)
                            .foregroundColor(AppColor.ink)
                        Text("Log in to keep tasting your memories.")
                            .font(AppFont.subheadline)
                            .foregroundColor(AppColor.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .bounceOnAppear()

                    // Card with fields
                    VStack(spacing: AppSpacing.l) {
                        AuthTextField(
                            label: "Email",
                            placeholder: "you@example.com",
                            input: $email,
                            icon: "envelope.fill"
                        )

                        AuthTextField(
                            label: "Password",
                            placeholder: "Your password",
                            input: $password,
                            type: .password,
                            icon: "lock.fill"
                        )

                        // Password reset confirmation
                        if viewModel.passwordResetSent {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Password reset email sent — check your inbox")
                            }
                            .font(AppFont.caption)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        HStack {
                            SecondaryButton(title: "Forgot password?") {
                                Task { await viewModel.forgotPassword(email: email) }
                            }
                            Spacer()
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, AppSpacing.l)
                    .bounceOnAppear(delay: 0.1)

                    // Login button
                    PrimaryButton(title: "Login", icon: "arrow.right", isLoading: isLoading) {
                        Task {
                            isLoading = true
                            await viewModel.login(email: email, password: password)
                            isLoading = false
                        }
                    }
                    .padding(.horizontal, AppSpacing.xxxl)
                    .bounceOnAppear(delay: 0.2)

                    // Divider with social-style note
                    HStack(spacing: AppSpacing.s) {
                        Rectangle().fill(AppColor.inkFaint.opacity(0.3)).frame(height: 1)
                        Text("OR")
                            .font(AppFont.tiny)
                            .foregroundColor(AppColor.inkFaint)
                        Rectangle().fill(AppColor.inkFaint.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal, AppSpacing.xxxl)

                    // Sign up
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(AppColor.inkMuted)
                        Button {
                            Haptics.tap()
                            showSignUp = true
                        } label: {
                            Text("Sign up")
                                .foregroundStyle(AppGradient.hero)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(AppFont.subheadline)
                    .padding(.bottom, AppSpacing.xl)
                    .sheet(isPresented: $showSignUp) {
                        SignUpView()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(AppAnimation.snappy, value: viewModel.passwordResetSent)
        .alert("Login Failed", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())
}
