//
//  AvatarView.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

struct AvatarView: View {
    var avatar : Image = Image("minion")
    
    var body: some View {
        avatar
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
    }
}

#Preview {
    AvatarView()
}
