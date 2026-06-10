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
            // Animated Background
            AnimatedBlobBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                
                // Top Card Container (Touches the absolute top, ends right above the button)
                VStack(spacing: 0) {
                    
                    // Custom Back Button Row
                    HStack {
                        Button(action: {
                            Haptics.soft() // Fixed the typo here!
                            dismiss()
                        }) {
                            Image(systemName: "arrow.backward")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 42, height: 42)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60) // Clears the notch / Dynamic Island area safely

                    // Main Title
                    Text("Sign Up")
                        .font(.clash(36, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Input Fields Scroll Area
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            customInputField(label: "Username", text: $username, isSecure: false)
                            customInputField(label: "Email", text: $email, isSecure: false)
                            customInputField(label: "Password", text: $password, isSecure: true)
                            customInputField(label: "Confirm Password", text: $confirmPassword, isSecure: true)

                            if !viewModel.errorMessage.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(viewModel.errorMessage)
                                }
                                .font(.clash(12, weight: .regular))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
                .background(
                    Color(red:248/255, green: 212/255, blue:209/255 ) // Translucent light card background
                    // red: 248/255,
                  //  green: 212/255,
                  //  blue: 209/255
                    
                        .clipShape(UnevenRoundedRectangle(
                            bottomLeadingRadius: 40,
                            bottomTrailingRadius: 40
                        ))
                )
                .ignoresSafeArea(edges: .top) // Forces the white container to touch the very top edge

                Spacer(minLength: 20) // The controlled gap right above the Create button

                // Bottom Controls Area
                VStack(spacing: 20) {
                    
                    // Create Button
                    Button(action: {
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
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create")
                                .font(.clash(22, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 236/255, green: 161/255, blue: 161/255))
                    //red: 236/255,
                    //green: 161/255,
                  //  blue: 161/255
                    // Your exact color requirements
                    .cornerRadius(22)
                    .padding(.horizontal, 32)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                    // Footer Link
                    Button(action: {
                        Haptics.soft()
                        dismiss()
                    }) {
                        Text("Already have an account? Log in")
                            .font(.clash(14, weight: .regular))
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.snappy, value: viewModel.errorMessage)
    }

    // Helper component to build form blocks cleanly
    @ViewBuilder
    private func customInputField(label: String, text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.clash(16, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                }
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(20)
        }
    }
}

#Preview {
    SignUpView()
}
