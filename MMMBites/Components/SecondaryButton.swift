//
//  SecondaryButton.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

struct SecondaryButton: View {
    var title: String
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(AppFont.subheadline)
                .foregroundColor(AppColor.inkMuted)
                .underline(isPressed, color: AppColor.secondary.opacity(0.6))
                .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.snappy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    SecondaryButton(title: "Have an account? Log in") { }
}
