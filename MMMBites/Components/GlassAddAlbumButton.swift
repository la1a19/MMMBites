//
//  GlassAddAlbumButton.swift
//  MMMBites
//
//  Created by Yat Tin lee on 9/6/2026.
//


import SwiftUI

struct GlassAddButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black.opacity(0.75))
                .frame(width: 52, height: 46)
                .background {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.65), lineWidth: 1)
                }
                .shadow(
                    color: .black.opacity(0.25),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 211/255, green: 245/255, blue: 244/255),
                Color(red: 247/255, green: 235/255, blue: 204/255),
                Color(red: 195/255, green: 236/255, blue: 255/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassAddButton {
            print("Add tapped")
        }
    }
}
