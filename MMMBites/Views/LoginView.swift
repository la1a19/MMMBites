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
    @State private var isLoggedIn = false
    @State private var errorMessage = ""
    
    var body: some View {
        if isLoggedIn {
            //AlbumsView(isLoggedIn: $isLoggedIn)
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
                
                HStack() {
                    //Remember Password
                    Button {
                        rememberPassword.toggle()
                    } label: {
                        HStack {
                            Image(systemName: rememberPassword ? "checkmark.square.fill" : "square")
                                .foregroundColor(rememberPassword ? .black : .gray)
                            Text("Remember Password")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    //Forgot Password
                    SecondaryButton(title: "Forgot Password") {
                        print("hello")
                    }
                    .font(.subheadline)
                    .padding()
                }
                
                //Login button
                PrimaryButton(title: "Login") {
                    print("hello")
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 50)
                
                //Sign up
                SecondaryButton(title: "Don't have an account? Sign up") {
                    print("hello")
                }
                .font(.subheadline)
            }
        }
    }
}

#Preview {
    LoginView()
}
