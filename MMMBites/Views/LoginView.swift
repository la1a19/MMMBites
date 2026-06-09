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

    var body: some View {
        ZStack {
            // Background
            AnimatedBlobBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {

                // Top spacing
                Spacer()
                    .frame(height: 120)

                // Title
                Text("Log in")
                    .font(.clash(42, weight: .bold))
                    .foregroundColor(.black)

                Spacer()
                    .frame(height: 60)

                // Main Form Container
                VStack(spacing: 24) {

                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.clash(17, weight: .semibold))

                        TextField("", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(18)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.clash(17, weight: .semibold))

                        SecureField("", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(18)
                    }

                    // Password Reset Message
                    if viewModel.passwordResetSent {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Password reset email sent")
                        }
                        .font(.clash(12))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Forgot Password
                    HStack {
                        Spacer()

                        Button("Forgot Password") {
                            Task {
                                await viewModel.forgotPassword(email: email)
                            }
                        }
                        .font(.clash(15))
                        .foregroundColor(.black)
                    }

                    Spacer()
                        .frame(height: 20)

                    // Login Button
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
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    Color(
                                        red: 0.10,
                                        green: 0.16,
                                        blue: 0.42
                                    )
                                )

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.clash(20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 60)
                    }

                    Spacer()

                    // Sign Up
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.clash(15))
                            .foregroundColor(.black)

                        Button("Sign up") {
                            showSignUp = true
                        }
                        .font(.clash(15, weight: .semibold))
                        .foregroundColor(.black)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Color(
                        red: 0.84,
                        green: 0.90,
                        blue: 0.97
                    )
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 45,
                        topTrailingRadius: 45
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
