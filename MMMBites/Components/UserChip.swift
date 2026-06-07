//
//  UserChip.swift
//  MMMBites
//
//  Created by Lila Lansang on 5/6/2026.
//

import SwiftUI

struct UserChip: View {
    var avatarData: String? = nil         // base64 JPEG stored in Firestore (free tier)
    var avatarURL: String? = nil          // remote avatar URL (e.g. Firebase Storage)
    var avatar: Image = Image("minion")   // local fallback
    var name: String

    private let avatarSize: CGFloat = 40   // bigger than capsule
    private let verticalInset: CGFloat = 2 // makes capsule shorter than avatar → avatar pokes out

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if let b64 = avatarData,
                   let data = Data(base64Encoded: b64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                } else if let urlString = avatarURL, let url = URL(string: urlString) {
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
                .font(.subheadline)
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
