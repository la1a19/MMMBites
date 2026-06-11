//
//  SearchFilterBar.swift
//  MMMBites
//
//  Created by Yat Tin lee on 9/6/2026.
//

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
        HStack(spacing: 10) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black.opacity(0.55))

                TextField("Search albums", text: $searchText)
                    .foregroundColor(.black)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Haptics.tap()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(.white.opacity(0.88))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(.white.opacity(0.65), lineWidth: 1)
            }
            .shadow(
                color: .black.opacity(0.16),
                radius: 4,
                x: 0,
                y: 2
            )

            // Filter button
            Button {
                Haptics.tap()
                withAnimation(.easeInOut) {
                    showFilters.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(showFilters ? .white : .black.opacity(0.75))
                    .frame(width: 52, height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .fill(showFilters ? AppColor.primary.opacity(0.82) : Color.white.opacity(0.34))
                            .background {
                                RoundedRectangle(cornerRadius: 23, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .stroke(.white.opacity(0.65), lineWidth: 1)
                    }
                    .shadow(
                        color: showFilters ? AppColor.primary.opacity(0.28) : .black.opacity(0.16),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
            .buttonStyle(.plain)
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
        .padding(.horizontal, 24)
    }
}
