//
//  LoginView.swift
//  MMMBites
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    @EnvironmentObject var viewModel: LoginViewModel

    @State private var showSignUp = false
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
                    .font(.clash(46, weight: .bold))
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.55), radius: 12, y: 2)

                Spacer()
                    .frame(height: 56)

                // Main Form Container — frosted glass card
                VStack(spacing: 22) {

                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.clash(15, weight: .semibold))
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

                    // Password Reset Message
                    if viewModel.passwordResetSent {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Password reset email sent")
                        }
                        .font(.clash(13, weight: .medium))
                        .foregroundColor(AppColor.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Forgot Password
                    HStack {
                        Spacer()

                        Button("Forgot password?") {
                            Task {
                                await viewModel.forgotPassword(email: email)
                            }
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
        .alert("Login Failed", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())
}
