//
//  SecondaryButton.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

//
//  PrimaryButton.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

struct SecondaryButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SecondaryButton(title: "Login") {
        print("Login")
    }
}
