//  WelcomeView.swift
//  MMMBites
//
//  Created by Jisu Kim on 4/6/2026.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animateLogo = false
    @State private var animateCTA = false

    var body: some View {
        NavigationStack {
            ZStack {
                
                // Animated Background (Left untouched as requested)
                AnimatedBlobBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack {
                    Spacer()

                    // Wordmark
                    Text("MMMBITES")
                        .font(.clash(32, weight: .medium))
                        .foregroundColor(.black)
                        .tracking(2)
                        .scaleEffect(animateLogo ? 1.0 : 0.92)
                        .opacity(animateLogo ? 1 : 0)

                    Spacer()

                    // CTA Button
                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Lets get started")
                            .font(.clash(16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 50)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.65))
                            )
                            .shadow(
                                color: Color.black.opacity(0.12),
                                radius: 12,
                                x: 0,
                                y: 8
                            )
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Haptics.soft()
                        }
                    )
                    .pressableScale()
                    .opacity(animateCTA ? 1 : 0)
                    .offset(y: animateCTA ? 0 : 20)
                    .padding(.bottom, 60)
                }
            }
            .onAppear {
                runIntro()
            }
        }
    }

    private func runIntro() {
        withAnimation(AppAnimation.bouncy.delay(0.05)) {
            animateLogo = true
        }

        withAnimation(AppAnimation.smooth.delay(0.45)) {
            animateCTA = true
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(LoginViewModel())
}
