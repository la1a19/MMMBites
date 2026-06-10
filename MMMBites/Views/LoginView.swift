//
//  LoginView.swift
//  MMMBites
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    @EnvironmentObject var viewModel: LoginViewModel

    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var isLoading = false

    private let buttonTop = AppColor.primary
    private let buttonBottom = AppColor.primary.opacity(0.85)
    private let cardTintTop = AppColor.background
    private let cardTintBottom = AppColor.secondary

    var body: some View {
        ZStack {
            // Background
            AnimatedBlobBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {

                Spacer()
                    .frame(height: 120)

                // Title — Clash font, subtle white halo for depth on the blobby bg
                Text("Log in")
                    .font(.clash(42, weight: .bold))
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.55), radius: 12, y: 2)

                Spacer()
                    .frame(height: 56)

                // Main Form Container — frosted glass card
                VStack(spacing: 22) {

                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.clash(17, weight: .semibold))
                            .foregroundColor(.black.opacity(0.78))
                            .padding(.leading, 4)

                        TextField("", text: $email)
                            .font(.clash(16, weight: .regular))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.72))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.clash(15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.78))
                            .padding(.leading, 4)

                        SecureField("", text: $password)
                            .font(.clash(16, weight: .regular))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.72))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
                    }

                    // Forgot Password
                    HStack {
                        Spacer()

                        Button("Forgot password?") {
                            Haptics.tap()
                            showForgotPassword = true
                        }
                        .font(.clash(13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.65))
                    }

                    Spacer()
                        .frame(height: 8)

                    // Login Button — navy gradient, glass shine stroke, colored shadow
                    Button {
                        Task {
                            isLoading = true
                            await viewModel.login(
                                email: email,
                                password: password
                            )
                            isLoading = false
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [buttonTop, buttonBottom],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.42),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                )

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.clash(18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 58)
                        .shadow(color: AppColor.primary.opacity(0.4), radius: 16, x: 0, y: 9)
                    }
                    .buttonStyle(.plain)

                    // "or continue with" separator
                    HStack(spacing: 12) {
                        Rectangle().fill(Color.black.opacity(0.15)).frame(height: 1)
                        Text("or")
                            .font(.clash(12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                        Rectangle().fill(Color.black.opacity(0.15)).frame(height: 1)
                    }
                    .padding(.top, 6)

                    SignInWithAppleButton(.signIn) { request in
                        viewModel.prepareAppleRequest(request)
                    } onCompletion: { result in
                        Task { await viewModel.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

                    Spacer()

                    // Sign Up
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.clash(14, weight: .regular))
                            .foregroundColor(.black.opacity(0.7))

                        Button("Sign up") {
                            showSignUp = true
                        }
                        .font(.clash(14, weight: .bold))
                        .foregroundColor(.black)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 26)
                .padding(.top, 44)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 45,
                        topTrailingRadius: 45,
                        style: .continuous
                    )
                    .fill(.ultraThinMaterial)
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 45,
                            topTrailingRadius: 45,
                            style: .continuous
                        )
                        .fill(
                            LinearGradient(
                                colors: [
                                    cardTintTop.opacity(0.72),
                                    cardTintBottom.opacity(0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 45,
                            topTrailingRadius: 45,
                            style: .continuous
                        )
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    )
                    .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: -6)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 45,
                        topTrailingRadius: 45,
                        style: .continuous
                    )
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(initialEmail: email)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Login Failed", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
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
            Haptics.success()
            isSuccess = true
            message = "Password reset email sent. Check your inbox."
        } catch let error as NSError {
            Haptics.warning()
            isSuccess = false
            message = readableResetError(error)
        }
    }

    private func readableResetError(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Enter a valid email address."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account was found for this email."
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
