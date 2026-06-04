//
//  AlbumsView.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//


import SwiftUI

struct AlbumsView: View {
    // Mock data for now. Replace with data from a ViewModel + Firestore later.
    @State private var albums: [Album] = [
        Album(title: "PARK", ownerId: "jisu", tags: ["Tree", "nature", "Picnic"]),
        Album(title: "BEACH", ownerId: "jisu", tags: ["Sea", "Summer", "Fun"]),
        Album(title: "DINNER", ownerId: "jisu", tags: ["Fancy", "Family"])
    ]

    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedTags: Set<String> = []   // tags the user is filtering by

    // All filter options shown when the filter panel is open
    private let filterOptions = ["Nature", "Picnic", "Fancy", "Family"]

    // Albums after applying selected tag filters + search text
    private var filteredAlbums: [Album] {
        albums.filter { album in
            // Tag filter: keep album if it has at least one selected tag
            let matchesTags = selectedTags.isEmpty ||
                !selectedTags.isDisjoint(with: Set(album.tags.map { $0.capitalized }))

            // Search filter: keep album if any tag contains the search text
            let matchesSearch = searchText.isEmpty ||
                album.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }

            return matchesTags && matchesSearch
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 20) {
                header

                if showFilters {
                    filterPills
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                titleRow

                searchRow

                Text("Your Bite Bubbles")
                    .font(.system(size: 28, weight: .bold))

                bubblesCarousel

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.78, green: 0.90, blue: 0.88),
                Color(red: 0.96, green: 0.93, blue: 0.80),
                Color(red: 0.80, green: 0.90, blue: 0.96)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                // open grid view
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding(10)
                    .background(.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                Text("Jisu")
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.white)
            .clipShape(Capsule())
        }
    }

    // MARK: - Filter pills (shown when filter is toggled)

    private var filterPills: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(filterOptions, id: \.self) { tag in
                Button {
                    withAnimation(.easeInOut) {
                        toggleTag(tag)
                    }
                } label: {
                    HStack {
                        Text(tag)
                            .fontWeight(.semibold)
                        Spacer()
                        // Show x if selected, plus if not
                        Image(systemName: selectedTags.contains(tag) ? "xmark" : "plus")
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(color(for: tag).opacity(selectedTags.contains(tag) ? 1.0 : 0.4))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Title

    private var titleRow: some View {
        HStack {
            Text("User's\nAlbums")
                .font(.system(size: 34, weight: .bold))
            Spacer()
            Button {
                // create new album
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.black)
                    .frame(width: 60, height: 44)
                    .background(.white.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Search + filter

    private var searchRow: some View {
        HStack(spacing: 0) {
            HStack {
                TextField("Search tag", text: $searchText)
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(Capsule())

            Button {
                withAnimation(.easeInOut) {
                    showFilters.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.black)
                    .padding(12)
            }
        }
        .background(.white.opacity(0.5))
        .clipShape(Capsule())
    }

    // MARK: - Bubbles carousel

    private var bubblesCarousel: some View {
        Group {
            if filteredAlbums.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No albums match your filters")
                        .foregroundColor(.gray)
                }
                .frame(height: 480)
            } else {
                TabView {
                    ForEach(filteredAlbums) { album in
                        albumBubble(album)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 480)
            }
        }
    }

    private func albumBubble(_ album: Album) -> some View {
        VStack(spacing: 16) {
            // Cover circle with OPEN ALBUM button
            ZStack {
                if let urlString = album.coverImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.3))
                    }
                    .frame(width: 300, height: 300)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }

                Button {
                    // open this album -> AlbumDetailView (to be built)
                } label: {
                    Text("OPEN ALBUM")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.8))
                        .clipShape(Capsule())
                }
            }

            // Album title + edit
            HStack {
                Text(album.title)
                    .font(.system(size: 32, weight: .bold))
                Button {
                    // edit album
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Tags
            HStack(spacing: 10) {
                ForEach(album.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(color(for: tag))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func color(for tag: String) -> Color {
        switch tag.lowercased() {
        case "tree", "nature": return Color.green
        case "picnic": return Color.orange
        case "fancy": return Color.yellow
        case "family": return Color.pink
        default: return Color.blue
        }
    }
}

#Preview {
    AlbumsView()
}
