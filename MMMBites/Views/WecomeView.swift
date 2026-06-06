//
//  WecomeView.swift
//  MMMBites
//
//  Created by Jisu Kim on 4/6/2026.
//


import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.85, blue: 0.95),
                        Color(red: 0.95, green: 0.92, blue: 0.80),
                        Color(red: 0.70, green: 0.80, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    Text("MMMBITES")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Lets get started")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .background(.white.opacity(0.6))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(LoginViewModel())
}
