//
//  LoginView.swift
//  MMMBites
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var rememberPassword = false
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel: LoginViewModel
    @State private var showSignUp = false
    @State private var showForgotPassword = false
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

                        HStack {
                            SecondaryButton(title: "Forgot password?") {
                                Haptics.tap()
                                showForgotPassword = true
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(initialEmail: email)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Login Failed", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isSending = false
    @State private var message: String?
    @State private var isSuccess = false

    init(initialEmail: String) {
        _email = State(initialValue: initialEmail.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)

            VStack(spacing: AppSpacing.l) {
                VStack(spacing: 6) {
                    Text("Reset password")
                        .font(.clash(22, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Text("Enter your account email and we'll send a reset link.")
                        .font(.clash(13, weight: .regular))
                        .foregroundColor(AppColor.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.l)

                AuthTextField(
                    label: "Email",
                    placeholder: "you@example.com",
                    input: $email,
                    icon: "envelope.fill"
                )

                if let message {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.clash(13, weight: .semibold))
                        Text(message)
                            .font(.clash(13, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(isSuccess ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background((isSuccess ? Color.green : Color.red).opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                }

                PrimaryButton(title: "Send reset email", icon: "paperplane.fill", isLoading: isSending) {
                    Task { await sendResetEmail() }
                }
                .disabled(isSending)

                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Text(isSuccess ? "Done" : "Cancel")
                        .font(.clash(14, weight: .semibold))
                        .foregroundColor(AppColor.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .disabled(isSending)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.xl)
        }
    }

    private func sendResetEmail() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            Haptics.warning()
            isSuccess = false
            message = "Enter your email first."
            return
        }

        isSending = true
        message = nil
        defer { isSending = false }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmed)
        } catch let error as NSError {
            // Silently treat "user not found" as success — surfacing it would
            // let anyone enumerate which emails are registered.
            if error.code != AuthErrorCode.userNotFound.rawValue {
                Haptics.warning()
                isSuccess = false
                message = readableResetError(error)
                return
            }
        }
        Haptics.success()
        isSuccess = true
        message = "If an account exists for this email, a reset link has been sent. Check your inbox."
    }

    private func readableResetError(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Enter a valid email address."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection and try again."
        default:
            return error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())
}
