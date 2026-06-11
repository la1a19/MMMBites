//  WelcomeView.swift
//  MMMBites
//
//  Created by Jisu Kim on 4/6/2026.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animateLogo = false
    @State private var animateTagline = false
    @State private var animateCTA = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    // Hero logo
                    VStack(spacing: AppSpacing.l) {
                        // Editorial monogram — elegant serif M inside a soft halo
                        ZStack {
                            Circle()
                                .fill(AppGradient.hero)
                                .frame(width: 150, height: 150)
                                .blur(radius: 24)
                                .opacity(0.55)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.9), Color.white.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 116, height: 116)

                            Text("M")
                                .font(.clash(72, weight: .light))
                                .italic()
                                .foregroundStyle(AppGradient.hero)
                                .tracking(-2)
                        }
                        .scaleEffect(animateLogo ? 1.0 : 0.7)
                        .opacity(animateLogo ? 1 : 0)

                        // Refined wordmark — thin serif with generous tracking
                        VStack(spacing: 10) {
                            Text("MMMBITES")
                                .font(.clash(30, weight: .light))
                                .foregroundColor(AppColor.ink)
                                .tracking(10)
                                .scaleEffect(animateLogo ? 1.0 : 0.92)
                                .opacity(animateLogo ? 1 : 0)

                            // Hairline accent line for editorial feel
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, AppColor.primary.opacity(0.6), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: animateLogo ? 120 : 0, height: 1)
                        }

                        Text("Savour every memory, one bite at a time.")
                            .font(.clash(14, weight: .regular))
                            .italic()
                            .foregroundColor(AppColor.inkMuted)
                            .tracking(0.5)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(animateTagline ? 1 : 0)
                            .offset(y: animateTagline ? 0 : 12)
                    }

                    Spacer()

                    // CTA
                    VStack(spacing: AppSpacing.m) {
                        NavigationLink {
                            LoginView()
                        } label: {
                            HStack(spacing: AppSpacing.s) {
                                Text("Let's get started")
                                    .font(.clash(16, weight: .medium))
                                    .tracking(1)
                                Image(systemName: "arrow.right")
                                    .font(.clash(14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 44)
                            .background(
                                Capsule().fill(AppGradient.hero)
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: AppColor.primary.opacity(0.35), radius: 16, y: 10)
                        }
                        .simultaneousGesture(TapGesture().onEnded { Haptics.soft() })
                        .pressableScale()

                        Text("No account yet? You'll set one up next.")
                            .font(.clash(12, weight: .regular))
                            .italic()
                            .foregroundColor(AppColor.inkFaint)
                            .tracking(0.3)
                    }
                    .opacity(animateCTA ? 1 : 0)
                    .offset(y: animateCTA ? 0 : 20)
                    .padding(.bottom, 60)
                }
            }
            .onAppear { runIntro() }
        }
    }

    private func runIntro() {
        withAnimation(AppAnimation.bouncy.delay(0.05)) {
            animateLogo = true
        }
        withAnimation(AppAnimation.smooth.delay(0.35)) {
            animateTagline = true
        }
        withAnimation(AppAnimation.smooth.delay(0.55)) {
            animateCTA = true
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(LoginViewModel())
}
