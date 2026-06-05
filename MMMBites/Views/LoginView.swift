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
        if viewModel.isLoggedIn {
            //AlbumsView(isLoggedIn: $isLoggedIn)
            VStack(spacing: 12) {
                //testing purposes (would insert the main albums page here)
                Text("woohoo ure logged in")
                    .font(.title2)
                    .bold()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Entered email: \(email)")
                    Text("Entered password: \(password)")
                    Text("Firebase user: \(Auth.auth().currentUser?.email ?? "nil")")
                    Text("UID: \(Auth.auth().currentUser?.uid ?? "nil")")
                }
                .font(.footnote)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 24)

                PrimaryButton(title: "Log out") {
                    viewModel.logout()
                }
                .padding(.horizontal, 50)
                .padding(.top, 20)
            }
        } else {
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
                
                //error message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 24)
                }

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
                SecondaryButton(title: "Don't have an account? Sign up") {
                    showSignUp = true
                }
                .font(.subheadline)
                .sheet(isPresented: $showSignUp) {
                    SignUpView()
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())
}
