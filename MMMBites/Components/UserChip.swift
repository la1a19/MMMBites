//
//  UserChip.swift
//  MMMBites
//
//  Created by Lila Lansang on 5/6/2026.
//

import SwiftUI

struct UserChip: View {
    var avatarURL: String? = nil          // remote avatar URL (e.g. Firebase Storage)
    var avatar: Image = Image("minion")   // local fallback if avatarURL is nil
    var name: String

    private let avatarSize: CGFloat = 60   // bigger than capsule
    private let verticalInset: CGFloat = 2 // makes capsule shorter than avatar → avatar pokes out

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if let urlString = avatarURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                } else {
                    avatar.resizable().scaledToFill()
                }
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())

            Text(name)
                .font(.title3)
                .foregroundColor(.black)
                .padding(.trailing, 20)
        }
        .background(
            Capsule()
                .fill(Color.white)
                .padding(.vertical, verticalInset)
        )
    }
}

#Preview {
    UserChip(name: "Jisu")
        .padding()
}
