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
    
    var body: some View {
        VStack() {
            Text("Log In")
                .font(.title)
                .bold()

            //Email and Password
            Group {
                AuthTextField(label: "Email", placeholder: "", input: $email)
                AuthTextField(label: "Password", placeholder: "", input: $password, type: .password)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            //password reset confirmation
            if viewModel.passwordResetSent {
                Text("Password reset email sent — check your inbox")
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.horizontal, 24)
            }

            HStack() { //didn't add 'remember me' checkbox because firebase already does that
                //Forgot Password
                SecondaryButton(title: "Forgot Password") {
                    Task { await viewModel.forgotPassword(email: email) }
                }
                .font(.subheadline)
                .padding(.horizontal, 30)
                Spacer()
            }

            //Login button
            PrimaryButton(title: "Login") {
                Task { await viewModel.login(email: email, password: password) }
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 50)

            //Sign up
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                Button("Sign Up") {
                    showSignUp = true
                }
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
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
