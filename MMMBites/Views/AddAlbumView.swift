//
//  AddAlbumView.swift
//  MMMBites
//
//  Created by Jisu Kim on 5/6/2026.
//


import SwiftUI
import MapKit
import Combine
import PhotosUI


struct AddAlbumView: View {
    @Environment(\.dismiss) var dismiss

    let albumToEdit: Album?   // nil = add new, non-nil = edit existing

    var onSave: (Album) -> Void = { _ in }

    @State private var title: String
    @State private var description: String
    @State private var location: String

    @State private var tags: [String]          // tags currently on THIS album
    @State private var searchText: String = ""
    @State private var selectedFriends: [String] = []
    @State private var showFriendPicker = false

    @State private var coverPickerItem: PhotosPickerItem?
    @State private var coverPhotoData: Data?
    @StateObject private var locationSearch = LocationSearchCompleter()
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    @FocusState private var isLocationFocused: Bool

    // Mock friends list — replace with Firestore users query later
    private let allFriends = ["Judy", "Mira", "Alex", "Sam", "Lila", "Nina", "Theo", "Ben"]
    private let existingTagOptions = Array(
        Set(MockData.allAlbums.flatMap { $0.tags })
    ).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }


    // Whether we are editing (affects title text, save behaviour)
    private var isEditing: Bool { albumToEdit != nil }


    init(albumToEdit: Album? = nil, onSave: @escaping (Album) -> Void = { _ in }) {
        self.albumToEdit = albumToEdit
        self.onSave = onSave
        // Pre-fill the form if editing, otherwise start empty
        _title = State(initialValue: albumToEdit?.title ?? "")
        _description = State(initialValue: albumToEdit?.description ?? "")
        _location = State(initialValue: albumToEdit?.location ?? "")
        _tags = State(initialValue: albumToEdit?.tags ?? [])
        _selectedFriends = State(initialValue: albumToEdit?.friendIds ?? [])
        _coverPhotoData = State(initialValue: albumToEdit?.coverPhotoData)
        _selectedLatitude = State(initialValue: albumToEdit?.latitude)
        _selectedLongitude = State(initialValue: albumToEdit?.longitude)

    }

    var body: some View {
        ZStack {

            AppBackground(variant: .warm)

            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    // Album name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ALBUM NAME")
                            .font(AppFont.tiny)
                            .foregroundColor(AppColor.inkMuted)
                            .padding(.leading, 6)
                        TextField("FANCY RESTO", text: $title)
                            .font(.clash(22, weight: .bold))
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    }
                    .padding(.horizontal, 24)
                    .bounceOnAppear()

                    descriptionField
                        .bounceOnAppear(delay: 0.03)

                    // Cover photo with edit overlay
                    coverPhoto
                        .bounceOnAppear(delay: 0.05)

                    VStack(spacing: AppSpacing.s) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(AppColor.primary)
                            TextField("Location", text: $location)
                                .font(AppFont.subheadline)
                                .focused($isLocationFocused)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.words)
                                .onChange(of: location) { _, newValue in
                                    selectedLatitude = nil
                                    selectedLongitude = nil
                                    locationSearch.update(query: newValue)
                                }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.85), in: Capsule(style: .continuous))
                        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))

                        if isLocationFocused && !locationSearch.completions.isEmpty {
                            locationSuggestions
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .bounceOnAppear(delay: 0.1)

                    // Existing tags
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Text("EXISTING TAGS")
                                .font(AppFont.captionBold)
                                .foregroundColor(AppColor.inkMuted)
                            Text("\(tags.count)")
                                .font(AppFont.tiny)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AppColor.secondary))
                            Spacer()
                            compactTagInput
                        }

                        if tags.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "tag")
                                Text("No tags yet — add one above")
                            }
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.inkFaint)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                                    .strokeBorder(
                                        AppColor.inkFaint.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                                    )
                            )
                        } else {
                            FlowLayout(spacing: 10) {
                                ForEach(tags, id: \.self) { tag in
                                    selectedTagChip(tag)
                                }
                            }
                        }

                        suggestedTags
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bounceOnAppear(delay: 0.2)

                    // Friends
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("FRIENDS")

                                .font(AppFont.captionBold)
                                .foregroundColor(AppColor.inkMuted)
                            Spacer()
                            Button {
                                Haptics.tap()
                                showFriendPicker = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.clash(13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(AppGradient.hero))
                                    .shadow(color: AppColor.primary.opacity(0.4), radius: 4, y: 2)
                            }
                            .buttonStyle(.plain)
                            .pressableScale(0.9)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.m) {
                                if selectedFriends.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.2")
                                        Text("Tap + to tag friends")
                                    }
                                    .font(AppFont.caption)
                                    .foregroundColor(AppColor.inkFaint)
                                    .padding(.vertical, 18)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                                            .strokeBorder(
                                                AppColor.inkFaint.opacity(0.4),
                                                style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                                            )
                                    )
                                } else {
                                    ForEach(selectedFriends, id: \.self) { friend in
                                        VStack(spacing: 6) {
                                            ZStack(alignment: .topTrailing) {
                                                AvatarView(initials: friend, size: 64, showRing: true)
                                                Button {
                                                    withAnimation(AppAnimation.snappy) {
                                                        selectedFriends.removeAll { $0 == friend }
                                                    }
                                                    Haptics.tap()
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.clash(9, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 18, height: 18)
                                                        .background(Circle().fill(AppColor.primary))
                                                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                                }
                                                .buttonStyle(.plain)
                                                .offset(x: 2, y: -2)
                                            }
                                            Text(friend)
                                                .font(AppFont.caption)
                                                .foregroundColor(AppColor.ink)
                                        }
                                        .transition(.scale.combined(with: .opacity))

                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    .bounceOnAppear(delay: 0.25)

                    // Save
                    PrimaryButton(title: isEditing ? "Save changes" : "Create album",
                                  icon: isEditing ? "checkmark" : "sparkles") {
                        Haptics.success()
                        saveAlbum()
                    }
                    .padding(.top, 4)
                    .bounceOnAppear(delay: 0.3)
                }
                .padding(AppSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(isEditing ? "Edit Album" : "New Album")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.clash(13, weight: .bold))
                        .foregroundColor(AppColor.ink)
                        .frame(width: 32, height: 32)
                        .background(AppGradient.glass, in: Circle())
                }
            }
        }
        .animation(AppAnimation.snappy, value: tags)
        .animation(AppAnimation.snappy, value: selectedFriends)

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


    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DESCRIPTION")
                .font(AppFont.tiny)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 6)

            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Add a short note about this album")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.inkFaint)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $description)
                    .font(AppFont.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(minHeight: 92)
            }
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .padding(.horizontal, 24)
    }

    private var coverPhoto: some View {
        PhotosPicker(
            selection: $coverPickerItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                Circle()
                    .fill(AppGradient.hero)
                    .frame(width: 260, height: 260)
                    .blur(radius: 24)
                    .opacity(0.4)

                if let coverPhotoData,
                   let image = UIImage(data: coverPhotoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 240, height: 240)
                        .clipShape(Circle())
                } else if let urlString = albumToEdit?.coverImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(AppColor.bgMint).shimmering()

                    }
                    .frame(width: 240, height: 240)
                    .clipShape(Circle())
                } else {
                    Circle()

                        .fill(AppGradient.glass)
                        .frame(width: 240, height: 240)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.clash(36, weight: .light))
                                    .foregroundColor(AppColor.inkFaint)
                                Text("Add cover photo")
                                    .font(AppFont.caption)
                                    .foregroundColor(AppColor.inkFaint)
                            }
                        )
                }

                // Edit (pencil) overlay
                Circle()
                    .fill(AppGradient.hero)
                    .frame(width: 76, height: 76)
                    .overlay(
                        Image(systemName: "square.and.pencil")
                            .font(.clash(28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: AppColor.primary.opacity(0.45), radius: 12, y: 6)
                    .offset(x: 70, y: 70)
            }
            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 3).frame(width: 240, height: 240))
        }
        .buttonStyle(.plain)
        .pressableScale(0.97)
        .onChange(of: coverPickerItem) { _, newItem in
            Task { await loadCoverPhoto(from: newItem) }
        }
    }

    // MARK: - Helpers

    private var compactTagInput: some View {
        HStack(spacing: 6) {
            TextField("Add tag", text: $searchText)
                .font(AppFont.caption)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .lineLimit(1)
                .frame(width: 88)
                .onSubmit { addTagFromSearch() }

            Button {
                addTagFromSearch()
                Haptics.soft()
            } label: {
                Image(systemName: "plus")
                    .font(.clash(11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppGradient.hero))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.86), in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private func selectedTagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .fontWeight(.semibold)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Button {
                withAnimation(AppAnimation.snappy) { removeTag(tag) }
                Haptics.tap()
            } label: {
                Image(systemName: "xmark")
                    .font(.clash(11, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .font(AppFont.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(AppColor.tag(tag)))
        .shadow(color: AppColor.tag(tag).opacity(0.4), radius: 6, y: 3)
        .transition(.scale.combined(with: .opacity))
    }

    private var suggestedTags: some View {
        let options = existingTagOptions.filter { option in
            !tags.contains { $0.caseInsensitiveCompare(option) == .orderedSame }
        }

        return VStack(alignment: .leading, spacing: 8) {
            if !options.isEmpty {
                Text("SUGGESTED TAGS")
                    .font(AppFont.tiny)
                    .foregroundColor(AppColor.inkMuted)
                    .padding(.leading, 4)

                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { tag in
                        Button {
                            addSuggestedTag(tag)
                        } label: {
                            Text(tag)
                                .font(AppFont.captionBold)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(AppColor.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.82), in: Capsule(style: .continuous))
                                .overlay(Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func addTagFromSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation(AppAnimation.bouncy) {
            tags.append(trimmed)
        }
        searchText = ""
        Haptics.success()
    }

    private func addSuggestedTag(_ tag: String) {
        guard !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { return }
        withAnimation(AppAnimation.bouncy) {
            tags.append(tag)
        }
        Haptics.selection()

    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func saveAlbum() {

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let album = Album(
            id: albumToEdit?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Album" : title,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            coverImageURL: albumToEdit?.coverImageURL,
            coverPhotoData: coverPhotoData,
            ownerId: albumToEdit?.ownerId ?? "jisu",
            tags: tags,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location,
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            date: albumToEdit?.date,
            friendIds: selectedFriends,
            createdAt: albumToEdit?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(album)
        dismiss()
    }

    private func loadCoverPhoto(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }

        await MainActor.run {
            withAnimation(AppAnimation.snappy) {
                coverPhotoData = data
            }
            Haptics.success()
        }
    }

    private var locationSuggestions: some View {
        VStack(spacing: 0) {
            ForEach(Array(locationSearch.completions.prefix(5).enumerated()), id: \.element) { index, completion in
                Button {
                    selectLocation(completion)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppColor.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .font(AppFont.subheadline.weight(.semibold))
                                .foregroundColor(AppColor.ink)
                                .lineLimit(1)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(AppFont.caption)
                                    .foregroundColor(AppColor.inkFaint)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if index < min(locationSearch.completions.count, 5) - 1 {
                    Divider().opacity(0.35)
                }
            }
        }
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        Haptics.selection()
        location = [completion.title, completion.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        isLocationFocused = false
        locationSearch.clear()

        Task {
            if let coordinate = await locationSearch.coordinate(for: completion) {
                await MainActor.run {
                    selectedLatitude = coordinate.latitude
                    selectedLongitude = coordinate.longitude
                }
            }
        }
    }
}

final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var completions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
            span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)
        )
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
        completions = []
        completer.queryFragment = ""
    }

    func coordinate(for completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        request.region = completer.region

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first?.location.coordinate
        } catch {
            return nil
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
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

            ZStack {
                AppBackground(variant: .warm)

                List {
                    ForEach(results, id: \.self) { friend in
                        Button {
                            withAnimation(AppAnimation.snappy) { toggle(friend) }
                            Haptics.selection()
                        } label: {
                            HStack(spacing: AppSpacing.m) {
                                AvatarView(initials: friend, size: 38)
                                Text(friend)
                                    .font(AppFont.body)
                                    .foregroundColor(AppColor.ink)
                                Spacer()
                                if selectedFriends.contains(friend) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppGradient.hero)
                                        .font(.clash(20, weight: .semibold))
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(AppColor.inkFaint)
                                        .font(.clash(20, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search friends")
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            }

            .navigationTitle("Tag Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {

                    Button("Done") {
                        Haptics.tap()
                        dismiss()
                    }
                    .fontWeight(.semibold)

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
