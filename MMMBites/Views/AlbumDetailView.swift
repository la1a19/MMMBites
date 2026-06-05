//
//  AlbumDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//


//
//  AlbumDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//

import SwiftUI

struct AlbumDetailView: View {
    let album: Album

    @State private var searchText = ""

    // Mock memories for now. Replace with data from a ViewModel + Firestore later.
    @State private var memories: [Memory] = [
        Memory(albumId: "1", title: "Picnic Fun"),
        Memory(albumId: "1", title: "Sandwiches"),
        Memory(albumId: "1", title: "Park fun"),
        Memory(albumId: "1", title: "Outdoors"),
        Memory(albumId: "1", title: "Snacks"),
        Memory(albumId: "1", title: "Desserts")
    ]

    // Memories filtered by the search text
    private var filteredMemories: [Memory] {
        if searchText.isEmpty {
            return memories
        }
        return memories.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Title + location
                    VStack(alignment: .leading, spacing: 6) {
                        Text(album.title)
                            .font(.system(size: 44, weight: .bold))

                        if let location = album.location {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.black)
                                Text(location)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }

                    // Participants + Add Memory
                    HStack {
                        // Participant avatars (placeholder)
                        HStack(spacing: -8) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(.pink.opacity(0.6))
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                            Text("+3")
                                .font(.caption.bold())
                                .padding(.leading, 4)
                        }

                        Spacer()

                        // Add Memory -> AddMemoryView (to be built)
                        NavigationLink {
                            Text("Add Memory screen (coming soon)")
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Memory")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.5))
                            .clipShape(Capsule())
                        }
                    }

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search Memories", text: $searchText)
                    }
                    .padding(12)
                    .background(.white)
                    .clipShape(Capsule())

                    // Memories grid (2 columns, regular layout)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(filteredMemories) { memory in
                            memoryBubble(memory)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Top-right user avatar (placeholder)
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "person.fill").font(.caption).foregroundColor(.gray))
                    Text("Jisu")
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Memory bubble

    private func memoryBubble(_ memory: Memory) -> some View {
        // Tapping a memory -> MemoryDetailView (to be built)
        NavigationLink {
            Text("Memory detail: \(memory.title) (coming soon)")
        } label: {
            VStack(spacing: 8) {
                if let urlString = memory.imageURLs.first, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.3))
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }

                Text(memory.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Background (temporary; replace with AppBackground() later)

    private var backgroundGradient: some View {
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
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(album: Album(
            title: "PARK",
            ownerId: "jisu",
            tags: ["Tree", "nature", "Picnic"],
            location: "Centennial Park, Sydney",
            date: Date()
        ))
    }
}
