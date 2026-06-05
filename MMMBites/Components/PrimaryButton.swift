//
//  PrimaryButton.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.black)
                .cornerRadius(12)
        }
    }
}

#Preview {
    PrimaryButton(title: "Login") {
        print("Login")
    }
}
