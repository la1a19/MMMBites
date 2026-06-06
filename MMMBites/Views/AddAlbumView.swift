//
//  AddAlbumView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//



import SwiftUI

struct AddAlbumView: View {
    @Environment(\.dismiss) var dismiss

    let albumToEdit: Album?   // nil = add new, non-nil = edit existing

    @State private var title: String
    @State private var location: String
    @State private var date: Date
    @State private var tags: [String]          // tags currently on THIS album
    @State private var searchText: String = ""
    @State private var selectedFriends: [String] = []
    @State private var showFriendPicker = false

    // Mock friends list — replace with Firestore users query later
    private let allFriends = ["Judy", "Mira", "Alex", "Sam", "Lila", "Nina", "Theo", "Ben"]

    // Whether we are editing (affects title text, save behaviour)
    private var isEditing: Bool { albumToEdit != nil }

    init(albumToEdit: Album? = nil) {
        self.albumToEdit = albumToEdit
        // Pre-fill the form if editing, otherwise start empty
        _title = State(initialValue: albumToEdit?.title ?? "")
        _location = State(initialValue: albumToEdit?.location ?? "")
        _date = State(initialValue: albumToEdit?.date ?? Date())
        _tags = State(initialValue: albumToEdit?.tags ?? [])
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 20) {

                    // Album name
                    TextField("FANCY RESTO", text: $title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.white.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 40)

                    // Cover photo with edit overlay
                    coverPhoto

                    // Location + date
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.purple)
                            TextField("Location", text: $location)
                                .font(.subheadline)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.words)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                            Text(date, style: .date)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 8)

                    // Search friend or tag + add button
                    HStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search friend or tag", text: $searchText)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                        }
                        .padding(12)
                        .background(.white)
                        .clipShape(Capsule())

                        Button {
                            addTagFromSearch()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.black)
                                .padding(12)
                        }
                    }
                    .background(.white.opacity(0.5))
                    .clipShape(Capsule())

                    // Existing tags (tags on this album, removable)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EXISTING TAGS")
                            .font(.subheadline.bold())

                        if tags.isEmpty {
                            Text("No tags yet")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            FlowLayout(spacing: 10) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 6) {
                                        Text(tag)
                                            .fontWeight(.semibold)
                                        Button {
                                            removeTag(tag)
                                        } label: {
                                            Image(systemName: "xmark")
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(color(for: tag))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Friends
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("FRIENDS")
                                .font(.subheadline.bold())
                            Spacer()
                            Button {
                                showFriendPicker = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(.white.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if selectedFriends.isEmpty {
                                    Text("Tap + to tag friends")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(selectedFriends, id: \.self) { friend in
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(.gray.opacity(0.3))
                                                .frame(width: 60, height: 60)
                                                .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                                            Text(friend)
                                                .font(.caption)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Save
                    Button {
                        saveAlbum()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.6))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .navigationTitle(isEditing ? "Edit Album" : "New Album")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(
                allFriends: allFriends,
                selectedFriends: $selectedFriends
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Cover photo

    private var coverPhoto: some View {
        Button {
            // open photo picker later
        } label: {
            ZStack {
                if let urlString = albumToEdit?.coverImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.2))
                    }
                    .frame(width: 240, height: 240)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 240, height: 240)
                }

                // Edit (pencil) overlay in the centre
                Circle()
                    .fill(.black.opacity(0.25))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    )
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

    // MARK: - Helpers

    private func addTagFromSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        searchText = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func saveAlbum() {
        // TODO: build Album from form fields and save/update via a ViewModel
        // if isEditing { update existing } else { create new }
        dismiss()
    }

    private func color(for tag: String) -> Color {
        switch tag.lowercased() {
        case "nature": return .green
        case "picnic": return .orange
        case "street food": return .purple
        case "fancy": return .yellow
        case "family": return .pink
        case "good view": return .blue
        default: return .gray
        }
    }
}

// MARK: - Friend picker sheet

struct FriendPickerSheet: View {
    let allFriends: [String]
    @Binding var selectedFriends: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return allFriends }
        return allFriends.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(results, id: \.self) { friend in
                    Button {
                        toggle(friend)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                            Text(friend)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFriends.contains(friend) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search friends")
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .navigationTitle("Tag Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ friend: String) {
        if let idx = selectedFriends.firstIndex(of: friend) {
            selectedFriends.remove(at: idx)
        } else {
            selectedFriends.append(friend)
        }
    }
}

// MARK: - FlowLayout

/// Lays out subviews left-to-right, wrapping to the next line when the row is full.
/// Each chip sizes to its intrinsic content width (no forced column width).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("Add") {
    NavigationStack {
        AddAlbumView()
    }
}

#Preview("Edit") {
    NavigationStack {
        AddAlbumView(albumToEdit: Album(
            title: "FANCY RESTO",
            ownerId: "jisu",
            tags: ["Nature", "Fancy", "Picnic"],
            location: "SupaFancy Resto, Sydney",
            date: Date()
        ))
    }
}
