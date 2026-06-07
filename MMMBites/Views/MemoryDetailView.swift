//
//  MemoryDetailView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//

import SwiftUI
import FirebaseFirestore

struct MemoryDetailView: View {
    let albumTitle: String
    let album: Album?
    var onUpdate: ((Memory) -> Void)? = nil
    var onDelete: ((Memory) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: LoginViewModel

    @State private var memory: Memory
    @State private var currentPhotoIndex = 0
    @State private var reactions: [Reaction]
    @State private var heartBurst = false
    @State private var bumpedEmoji: String? = nil
    @State private var showEditSheet = false
    @State private var showEmojiPicker = false
    @State private var showNoteEditor = false
    @State private var favouriteBurst = false

    @State private var friendUsers: [User] = []

    private let similarMemories: [SimilarMemoryEntry]

    init(
        memory: Memory,
        albumTitle: String,
        album: Album? = nil,
        similarMemories: [SimilarMemoryEntry] = [],
        onUpdate: ((Memory) -> Void)? = nil,
        onDelete: ((Memory) -> Void)? = nil
    ) {
        self.albumTitle = albumTitle
        self.album = album
        self.similarMemories = similarMemories
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _memory = State(initialValue: memory)
        _reactions = State(initialValue: memory.reactions)
    }

    private var currentUserID: String? {
        authViewModel.currentUser?.id
    }

    private var canEditMemory: Bool {
        memory.capturedById == currentUserID
    }

    private var isFavourite: Bool {
        memory.isFavourite ?? false
    }

    private var reactionCounts: [(emoji: String, count: Int)] {
        let grouped = Dictionary(grouping: reactions, by: { $0.emoji })
        return grouped.map { (emoji: $0.key, count: $0.value.count) }
            .sorted { $0.emoji < $1.emoji }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    MemoryHeader(
                        memory: memory,
                        currentPhotoIndex: $currentPhotoIndex,
                        heartBurst: heartBurst,
                        onDoubleTapLove: triggerDoubleTapLove
                    )
                    .bounceOnAppear()

                    MemoryTitleSection(
                        memory: memory,
                        albumTitle: albumTitle,
                        isFavourite: isFavourite,
                        favouriteBurst: favouriteBurst,
                        canEditMemory: canEditMemory,
                        onEdit: openEditSheet
                    )
                    .bounceOnAppear(delay: 0.06)

                    MemoryLocationRow(memory: memory)
                        .bounceOnAppear(delay: 0.1)

                    MemoryCapturedByRow(
                        capturedByName: capturedByName,
                        capturedByAvatar: capturedByAvatar
                    )
                    .bounceOnAppear(delay: 0.14)

                    MemoryNoteCard(
                        memory: memory,
                        canEditMemory: canEditMemory,
                        onEditNote: openNoteEditor
                    )
                    .bounceOnAppear(delay: 0.18)

                    MemoryExtrasCard(
                        memory: memory,
                        friendName: friendName(for:),
                        friendAvatarImage: friendAvatarImage(for:)
                    )
                    .bounceOnAppear(delay: 0.22)

                    MemoryReactionsSection(
                        reactionCounts: reactionCounts,
                        bumpedEmoji: bumpedEmoji,
                        hasReacted: hasReacted(_:),
                        onAddReaction: addReaction(_:),
                        onOpenPicker: openEmojiPicker
                    )
                    .bounceOnAppear(delay: 0.26)

                    MemorySimilarSection(similarMemories: similarMemories)
                        .bounceOnAppear(delay: 0.32)
                }
                .padding(AppSpacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.clash(13, weight: .semibold))
                    Text(albumTitle)
                        .font(AppFont.subheadline.weight(.semibold))
                }
                .foregroundColor(AppColor.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(
                        item: shareText,
                        subject: Text(memory.title),
                        message: Text(albumTitle)
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        toggleFavourite()
                    } label: {
                        Label(
                            isFavourite ? "Remove from favourites" : "Add to favourites",
                            systemImage: isFavourite ? "heart.slash" : "heart"
                        )
                    }
                    if canEditMemory {
                        Button(role: .destructive) {
                            Haptics.warning()
                            onDelete?(memory)
                            dismiss()
                        } label: {
                            Label("Delete memory", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.clash(20, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddMemoryView(
                    album: album ?? Album(id: memory.albumId, title: albumTitle, ownerId: ""),
                    memoryToEdit: memory
                ) { updated in
                    withAnimation(AppAnimation.snappy) {
                        memory = updated
                        reactions = updated.reactions
                    }
                    onUpdate?(updated)
                }
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            MemoryEmojiPickerSheet { emoji in
                addReaction(emoji)
                showEmojiPicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNoteEditor) {
            MemoryNoteEditorSheet(
                initialNote: memory.note,
                isEdit: memory.note != nil
            ) { newNote in
                withAnimation(AppAnimation.snappy) {
                    memory.note = newNote
                }
                onUpdate?(memory)
                Haptics.success()
                showNoteEditor = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task(id: friendsLoadKey) {
            await loadFriends()
        }
    }
}

private extension MemoryDetailView {
    var friendsLoadKey: [String] {
        (authViewModel.currentUser?.friendIDs ?? [])
        + memory.participantIds
        + [memory.capturedById].compactMap { $0 }
    }

    var capturedByName: String {
        guard let capturedById = memory.capturedById else { return "Unknown" }
        return friendName(for: capturedById)
    }

    var capturedByAvatar: Image? {
        guard let capturedById = memory.capturedById else { return nil }
        return friendAvatarImage(for: capturedById)
    }

    var recapContextText: String {
        var parts: [String] = []

        if !memory.participantIds.isEmpty {
            let names = memory.participantIds.prefix(3).map(friendName(for:))
            parts.append("with \(joinedNames(names))")
        }

        if let location = memory.location, !location.isEmpty {
            parts.append("at \(location)")
        }

        if !memory.memorableTags.isEmpty {
            let labels = memory.memorableTags.prefix(3).map { $0.lowercased() }
            parts.append(", remembered for \(joinedNames(labels))")
        }

        guard !parts.isEmpty else {
            return "This meal kept its own kind of memory."
        }

        var sentence = parts[0]
        for part in parts.dropFirst() {
            sentence += part.hasPrefix(",") ? part : " \(part)"
        }
        return sentence.prefix(1).uppercased() + sentence.dropFirst() + "."
    }

    var shareText: String {
        var lines: [String] = []
        lines.append("\"\(memory.title)\"")

        if let mood = memory.mood {
            lines.append("\(mood.emoji) A \(mood.label.lowercased()) memory in \(albumTitle)")
        } else {
            lines.append("From \(albumTitle)")
        }

        if let location = memory.location, !location.isEmpty {
            lines.append("📍 \(location)")
        }

        lines.append("")
        lines.append(memory.note?.isEmpty == false ? memory.note! : memory.recapSentence(nameFor: friendName(for:)))

        if let bite = memory.bestBite, !bite.isEmpty {
            lines.append("")
            lines.append("🍴 Best bite: \(bite)")
        }

        lines.append("")
        lines.append("— Shared from MMMBites")
        return lines.joined(separator: "\n")
    }

    func loadFriends() async {
        let ids = Set(friendsLoadKey)
        guard !ids.isEmpty else {
            friendUsers = []
            return
        }

        let database = Firestore.firestore()
        var loaded: [User] = []
        for chunk in Array(ids).chunked(into: 30) {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                loaded.append(contentsOf: snapshot.documents.compactMap {
                    try? $0.data(as: User.self)
                })
            } catch {
                print("[MemoryDetailView] friend load error: \(error)")
            }
        }
        friendUsers = loaded
    }

    func friendName(for id: String) -> String {
        friendUsers.first(where: { $0.id == id })?.username ?? id
    }

    func friendAvatarImage(for id: String) -> Image? {
        guard
            let base64 = friendUsers.first(where: { $0.id == id })?.avatarData,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    func joinedNames<S: Sequence>(_ values: S) -> String where S.Element == String {
        let array = Array(values)
        switch array.count {
        case 0:
            return ""
        case 1:
            return array[0]
        case 2:
            return "\(array[0]) and \(array[1])"
        default:
            return array.dropLast().joined(separator: ", ") + ", and \(array.last ?? "")"
        }
    }

    func openEditSheet() {
        Haptics.tap()
        showEditSheet = true
    }

    func openEmojiPicker() {
        Haptics.tap()
        showEmojiPicker = true
    }

    func openNoteEditor() {
        Haptics.tap()
        showNoteEditor = true
    }

    func hasReacted(_ emoji: String) -> Bool {
        guard let currentUserID else { return false }
        return reactions.contains { $0.userId == currentUserID && $0.emoji == emoji }
    }

    func addReaction(_ emoji: String) {
        guard let currentUserID else { return }
        Haptics.selection()
        bumpedEmoji = emoji
        withAnimation(AppAnimation.bouncy) {
            reactions.append(Reaction(userId: currentUserID, emoji: emoji))
            memory.reactions = reactions
        }
        onUpdate?(memory)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            bumpedEmoji = nil
        }
    }

    func triggerDoubleTapLove() {
        Haptics.success()
        addReaction("❤️")
        withAnimation(AppAnimation.bouncy) { heartBurst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(AppAnimation.smooth) { heartBurst = false }
        }
    }

    func toggleFavourite() {
        let next = !isFavourite
        Haptics.selection()
        withAnimation(AppAnimation.bouncy) {
            memory.isFavourite = next
            favouriteBurst = next
        }
        onUpdate?(memory)
        if next {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(AppAnimation.smooth) { favouriteBurst = false }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MemoryDetailView(
            memory: Memory(
                albumId: "1",
                title: "Picnic Fun",
                note: "We had so much fun at the park today, I went with my super amazing friends and we ate super good food.",
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
            albumTitle: "Park"
        )
        .environmentObject(LoginViewModel())
    }
}
