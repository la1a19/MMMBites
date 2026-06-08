//
//  SearchFilterBar.swift
//  MMMBites
//
//  Created by Yat Tin lee on 5/6/2026.
//

import SwiftUI

struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left search area: 70%
                HStack {
                    TextField("Search tag", text: $searchText)

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .frame(width: geometry.size.width * 0.7, height: 46)
                .background(.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 23,
                        bottomLeadingRadius: 23,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )

                // Right filter button: 30%
                Button {
                    withAnimation(.easeInOut) {
                        showFilters.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.black.opacity(0.75))
                        .frame(width: geometry.size.width * 0.3, height: 46)
                        .background {
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 23,
                                topTrailingRadius: 23
                            )
                            .fill(.ultraThinMaterial)
                        }
                        .overlay {
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 23,
                                topTrailingRadius: 23
                            )
                            .stroke(.white.opacity(0.65), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
            .compositingGroup()
            .shadow(
                color: .black.opacity(0.25),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .frame(height: 46)
    }
}

#Preview {
    ZStack {
        AppBackground()

        SearchFilterBar(
            searchText: .constant(""),
            showFilters: .constant(false)
        )
        .padding(.horizontal, 12)
    }
}
