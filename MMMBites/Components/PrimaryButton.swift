//
//  PrimaryButton.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            HStack(spacing: AppSpacing.s) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.clash(16, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(AppGradient.primaryButton)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: AppColor.primary.opacity(0.35), radius: 14, x: 0, y: 8)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(AppAnimation.snappy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Login") { }
        PrimaryButton(title: "Continue", icon: "arrow.right") { }
        PrimaryButton(title: "Loading", isLoading: true) { }
    }
    .padding()
}
