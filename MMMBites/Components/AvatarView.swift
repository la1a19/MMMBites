//
//  AvatarView.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

struct AvatarView: View {
    var avatar: Image? = nil
    var initials: String? = nil
    var size: CGFloat = 50
    var showRing: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppGradient.hero.opacity(0.85))

            if let avatar {
                avatar
                    .resizable()
                    .scaledToFill()
            } else if let initials, !initials.isEmpty {
                Text(String(initials.prefix(2)).uppercased())
                    .font(.clash(size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.clash(size * 0.45, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(showRing ? 0.9 : 0.5), lineWidth: showRing ? 2.5 : 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(size: 60)
        AvatarView(initials: "JS", size: 60)
        AvatarView(initials: "Lila", size: 60, showRing: true)
    }
    .padding()
    .background(AppBackground())
}
