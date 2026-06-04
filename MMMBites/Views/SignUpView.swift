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
    
    @StateObject private var viewModel = LoginViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        VStack() {
            Text("Sign Up")
                .font(.title)
                .bold()
            
            //Email and Password
            Group {
                AuthTextField(label: "Username", placeholder: "", input: $username)
                AuthTextField(label: "Email", placeholder: "", input: $email)
                AuthTextField(label: "Password", placeholder: "", input: $password, type: .password)
                AuthTextField(label: "Confirm Password", placeholder: "", input: $confirmPassword, type: .password)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        //error message
        if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .padding(.horizontal, 24)
        }
        
        //Create button
        PrimaryButton(title: "Create") {
            guard password == confirmPassword else {
                viewModel.errorMessage = "Passwords don't match"
                return
            }
            viewModel.signup(email: email, password: password)
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 20)

        //Go back to log in page (close sheet)
        SecondaryButton(title: "Have an account? Log in") {
            dismiss()
        }
        .font(.subheadline)
    }
}

#Preview {
    SignUpView()
}
