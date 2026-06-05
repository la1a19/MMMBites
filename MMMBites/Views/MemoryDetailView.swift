//
//  MemoryDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//



import SwiftUI

struct MemoryDetailView: View {
    let memory: Memory
    let albumTitle: String

    // Mock current user id (later: from auth)
    private let currentUserId = "jisu"

    @State private var currentPhotoIndex = 0
    @State private var reactions: [Reaction]

    // All emojis available as reactions (shown inline as toggle chips)
    private let availableEmojis = ["❤️", "😋", "👍", "😂", "🔥"]

    // Mock "similar memories" for now (later: real logic via ViewModel)
    private let similarMemories: [Memory]

    init(memory: Memory, albumTitle: String, similarMemories: [Memory] = []) {
        self.memory = memory
        self.albumTitle = albumTitle
        self.similarMemories = similarMemories
        _reactions = State(initialValue: memory.reactions)
    }

    // Group reactions by emoji to show counts (❤️ 1, 😋 2)
    private var reactionCounts: [(emoji: String, count: Int)] {
        let grouped = Dictionary(grouping: reactions, by: { $0.emoji })
        return grouped.map { (emoji: $0.key, count: $0.value.count) }
            .sorted { $0.emoji < $1.emoji }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Photo carousel with arrows
                    photoCarousel

                    // Album + date
                    HStack {
                        Text("Album : \(albumTitle)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(memory.date, style: .date)
                        }
                        .font(.subheadline)
                        .foregroundColor(.black)
                    }

                    // Title + edit
                    HStack {
                        Text(memory.title)
                            .font(.system(size: 32, weight: .bold))
                        Button {
                            // edit memory later
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.black)
                        }
                    }

                    // Location
                    if let location = memory.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.black)
                            Text(location)
                                .font(.subheadline)
                        }
                    }

                    // Captured by
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                        VStack(alignment: .leading) {
                            Text("Captured by")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(memory.capturedById ?? "Unknown")
                                .font(.subheadline.bold())
                        }
                    }

                    // Note entry
                    if let note = memory.note {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note Entry")
                                .font(.headline)
                            Text(note)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Reactions
                    reactionsRow

                    // Similar memories
                    if !similarMemories.isEmpty {
                        VStack(spacing: 12) {
                            Text("Similar memories")
                                .font(.title3.bold())
                            HStack(spacing: 12) {
                                ForEach(similarMemories) { sim in
                                    Circle()
                                        .fill(.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Back to \(albumTitle)")
    }

    // MARK: - Photo carousel

    private var photoCarousel: some View {
        ZStack {
            if memory.imageURLs.isEmpty {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
            } else {
                TabView(selection: $currentPhotoIndex) {
                    ForEach(memory.imageURLs.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: memory.imageURLs[index])) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(.gray.opacity(0.3))
                        }
                        .frame(height: 300)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Left / right arrows
                HStack {
                    Button {
                        if currentPhotoIndex > 0 { currentPhotoIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    Spacer()
                    Button {
                        if currentPhotoIndex < memory.imageURLs.count - 1 { currentPhotoIndex += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
            }
        }
    }

    // MARK: - Reactions

    private var reactionsRow: some View {
        HStack(spacing: 10) {
            ForEach(reactionCounts, id: \.emoji) { item in
                Button {
                    toggleReaction(item.emoji)
                } label: {
                    HStack(spacing: 4) {
                        Text(item.emoji)
                        Text("\(item.count)")
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(hasReacted(item.emoji) ? Color.purple.opacity(0.2) : .white)
                    .clipShape(Capsule())
                }
            }

            // Add reaction
            Menu {
                ForEach(["❤️", "😋", "👍", "😂", "🔥"], id: \.self) { emoji in
                    Button(emoji) { toggleReaction(emoji) }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Reaction logic

    // Has the current user reacted with this emoji?
    private func hasReacted(_ emoji: String) -> Bool {
        reactions.contains { $0.userId == currentUserId && $0.emoji == emoji }
    }

    // Toggle the current user's reaction for an emoji
    private func toggleReaction(_ emoji: String) {
        if let index = reactions.firstIndex(where: { $0.userId == currentUserId && $0.emoji == emoji }) {
            // Already reacted -> remove
            reactions.remove(at: index)
        } else {
            // Not reacted -> add
            reactions.append(Reaction(userId: currentUserId, emoji: emoji))
        }
        // TODO: persist this change to Firestore via a ViewModel
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
        MemoryDetailView(
            memory: Memory(
                albumId: "1",
                title: "Picnic Fun",
                note: "We had so much fun at the park today, I went with my super amazing friends and we ate super good food. Everyone brought their own food, I brought fairy bread and everyone said it was super good.",
                imageURLs: [],
                location: "Centennial Park, Sydney",
                capturedById: "Jisu",
                reactions: [
                    Reaction(userId: "jisu", emoji: "❤️"),
                    Reaction(userId: "ada", emoji: "😋"),
                    Reaction(userId: "tin", emoji: "😋")
                ],
                date: Date()
            ),
            albumTitle: "Park",
            similarMemories: [
                Memory(albumId: "1", title: "Sim 1"),
                Memory(albumId: "1", title: "Sim 2"),
                Memory(albumId: "1", title: "Sim 3")
            ]
        )
    }
}
