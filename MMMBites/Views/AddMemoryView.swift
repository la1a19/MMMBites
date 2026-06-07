//
//  AddMemoryView.swift
//  MMMBites
//
//  Form for recording a meal memory — mood, best bite, who was there,
//  and what made it memorable.
//

import SwiftUI
import PhotosUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct AddMemoryView: View {
    let album: Album
    let memoryToEdit: Memory?
    var onSave: (Memory) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: LoginViewModel

    @State private var title: String
    @State private var mood: MemoryMood?
    @State private var memorableTags: [String]
    @State private var memorableTagSearchText: String = ""
    @State private var bestBite: String
    @State private var note: String
    @State private var participants: [String]    // user IDs of tagged friends
    @State private var date: Date
    @State private var location: String
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    @StateObject private var locationSearch = LocationSearchCompleter()
    @FocusState private var isLocationFocused: Bool
    @State private var showFriendPicker = false
    @State private var showDatePicker = false
    @State private var showOptionalDetails: Bool

    // Photo picking
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photoData: [Data]

    // Real friends loaded from Firestore for the picker / display.
    @State private var friendUsers: [User] = []
    @State private var isLoadingFriends = false

    private var isEditing: Bool { memoryToEdit != nil }

    init(
        album: Album,
        memoryToEdit: Memory? = nil,
        onSave: @escaping (Memory) -> Void = { _ in }
    ) {
        self.album = album
        self.memoryToEdit = memoryToEdit
        self.onSave = onSave

        _title             = State(initialValue: memoryToEdit?.title ?? "")
        _mood              = State(initialValue: memoryToEdit?.mood)
        _memorableTags     = State(initialValue: memoryToEdit?.memorableTags ?? [])
        _bestBite          = State(initialValue: memoryToEdit?.bestBite ?? "")
        _note              = State(initialValue: memoryToEdit?.note ?? "")
        _participants      = State(initialValue: memoryToEdit?.participantIds ?? [])
        _date              = State(initialValue: memoryToEdit?.date ?? Date())
        _photoData         = State(initialValue: memoryToEdit?.photoData ?? [])
        _location          = State(initialValue: memoryToEdit?.location ?? album.location ?? "")
        _selectedLatitude  = State(initialValue: memoryToEdit?.latitude ?? album.latitude)
        _selectedLongitude = State(initialValue: memoryToEdit?.longitude ?? album.longitude)
        _showOptionalDetails = State(initialValue: memoryToEdit != nil)
    }

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)

            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    titleField
                        .bounceOnAppear()

                    photosField
                        .bounceOnAppear(delay: 0.03)

                    HStack(alignment: .top, spacing: AppSpacing.m) {
                        dateSection
                        locationSection
                    }
                    .bounceOnAppear(delay: 0.05)

                    optionalDetailsToggle
                        .bounceOnAppear(delay: 0.08)

                    if showOptionalDetails {
                        optionalDetails
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .bounceOnAppear(delay: 0.1)
                    }

                    PrimaryButton(
                        title: isEditing ? "Save changes" : "Save meal memory",
                        icon: isEditing ? "checkmark" : "sparkles"
                    ) {
                        save()
                    }
                    .padding(.top, 4)
                    .bounceOnAppear(delay: 0.3)
                }
                .padding(AppSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(isEditing ? "Edit Meal Memory" : "Start a Meal Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.clash(13, weight: .bold))
                        .foregroundColor(AppColor.ink)
                        .frame(width: 32, height: 32)
                        .glassCircleSurface()
                }
            }
        }
        .animation(AppAnimation.snappy, value: mood)
        .animation(AppAnimation.snappy, value: memorableTags)
        .animation(AppAnimation.snappy, value: participants)
        .animation(AppAnimation.snappy, value: showOptionalDetails)
        .task(id: authViewModel.currentUser?.friendIDs ?? []) {
            await loadFriends()
        }
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(
                allFriends: friendUsers,
                selectedFriendIDs: $participants,
                isLoading: isLoadingFriends
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Friend loading

    private func loadFriends() async {
        let friendIDs = authViewModel.currentUser?.friendIDs ?? []
        guard !friendIDs.isEmpty else {
            friendUsers = []
            return
        }

        isLoadingFriends = true
        defer { isLoadingFriends = false }

        let database = Firestore.firestore()
        var loaded: [User] = []
        for chunk in friendIDs.chunked(into: 30) {
            do {
                let snapshot = try await database
                    .collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                loaded.append(contentsOf: snapshot.documents.compactMap {
                    try? $0.data(as: User.self)
                })
            } catch {
                print("[AddMemoryView] friend load error: \(error)")
            }
        }
        friendUsers = loaded.sorted {
            $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending
        }
    }

    private func friendName(for id: String) -> String {
        friendUsers.first(where: { $0.id == id })?.username ?? "Unknown"
    }

    private func friendAvatarImage(for id: String) -> Image? {
        guard
            let base64 = friendUsers.first(where: { $0.id == id })?.avatarData,
            let data = Data(base64Encoded: base64),
            let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }

    // MARK: - Photos

    private var photosField: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("PHOTOS")

            if photoData.isEmpty {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 5,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.clash(15, weight: .semibold))
                        Text("Pick a few photos to remember this meal by")
                            .font(.clash(12, weight: .semibold))
                    }
                    .foregroundColor(AppColor.inkMuted)
                    .padding(.vertical, 22)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.52), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                            .strokeBorder(
                                AppColor.primary.opacity(0.42),
                                style: StrokeStyle(lineWidth: 1.4, dash: [4, 4])
                            )
                    )
                }
                .buttonStyle(.plain)
                .pressableScale(0.98)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.s) {
                        ForEach(Array(photoData.enumerated()), id: \.offset) { idx, data in
                            if let uiImage = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.s,
                                                                    style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.s,
                                                             style: .continuous)
                                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                                    Button {
                                        Haptics.tap()
                                        withAnimation(AppAnimation.snappy) {
                                            photoData.remove(at: idx)
                                            if idx < pickerItems.count {
                                                pickerItems.remove(at: idx)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.clash(9, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(AppColor.primary))
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        PhotosPicker(
                            selection: $pickerItems,
                            maxSelectionCount: 5,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            VStack(spacing: 7) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.clash(18, weight: .semibold))
                                Text("Change")
                                    .font(AppFont.tiny)
                            }
                            .foregroundColor(AppColor.inkMuted)
                            .frame(width: 86, height: 110)
                            .background(Color.white.opacity(0.54), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                                    .strokeBorder(
                                        AppColor.primary.opacity(0.42),
                                        style: StrokeStyle(lineWidth: 1.3, dash: [4, 4])
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .pressableScale(0.96)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: pickerItems) { _, newItems in
            Task { await loadPickedPhotos(newItems) }
        }
    }

    private func loadPickedPhotos(_ items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        await MainActor.run {
            withAnimation(AppAnimation.snappy) {
                photoData = loaded
            }
            Haptics.success()
        }
    }

    // MARK: - Title

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("WHAT TO CALL THIS MEMORY")
            TextField("e.g. Sunday roast with the girls", text: $title)
                .font(.clash(20, weight: .semibold))
                .multilineTextAlignment(.center)
                .autocorrectionDisabled(true)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .fieldSurface()
        }
    }

    // MARK: - Optional details

    private var optionalDetailsToggle: some View {
        Button {
            Haptics.tap()
            withAnimation(AppAnimation.snappy) {
                showOptionalDetails.toggle()
            }
        } label: {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(AppColor.secondary.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: showOptionalDetails ? "minus" : "plus")
                        .font(.clash(13, weight: .bold))
                        .foregroundColor(AppColor.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(showOptionalDetails ? "Hide details" : "Add details")
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.ink)
                    Text("Mood, best bite, tags, people, and note")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Image(systemName: showOptionalDetails ? "chevron.up" : "chevron.down")
                    .font(.clash(11, weight: .bold))
                    .foregroundColor(AppColor.inkFaint)
            }
            .glassCard(radius: AppRadius.m, padding: AppSpacing.l)
        }
        .buttonStyle(.plain)
        .pressableScale(0.98)
    }

    private var optionalDetails: some View {
        VStack(spacing: AppSpacing.xl) {
            moodSection
            memorableSection
            bestBiteSection
            peopleSection
            noteSection
        }
    }

    // MARK: - Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WHEN")

            Button {
                Haptics.tap()
                withAnimation(AppAnimation.snappy) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColor.secondary)
                    Text(date, style: .date)
                        .font(.clash(13, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .pillSurface()
            }
            .buttonStyle(.plain)

            if showDatePicker {
                DatePicker("Memory date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppColor.primary)
                    .padding(8)
                    .glassCard(radius: AppRadius.m, padding: 0)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("LOCATION")

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(AppColor.primary)
                TextField("e.g. Bills, Bondi", text: $location)
                    .font(.clash(13, weight: .semibold))
                    .focused($isLocationFocused)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit { useTypedLocation() }
                    .onChange(of: location) { _, newValue in
                        selectedLatitude = nil
                        selectedLongitude = nil
                        locationSearch.update(query: newValue)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .pillSurface()

            if isLocationFocused && shouldShowLocationSuggestions {
                locationSuggestions
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowLocationSuggestions: Bool {
        !trimmedLocation.isEmpty &&
        (!locationSearch.completions.isEmpty || !matchesTopCompletion)
    }

    private var matchesTopCompletion: Bool {
        guard let top = locationSearch.completions.first else { return false }
        return top.title.localizedCaseInsensitiveCompare(trimmedLocation) == .orderedSame
    }

    private func useTypedLocation() {
        guard !trimmedLocation.isEmpty else { return }
        Haptics.selection()
        location = trimmedLocation
        selectedLatitude = nil
        selectedLongitude = nil
        isLocationFocused = false
        locationSearch.clear()
    }

    private var locationSuggestions: some View {
        VStack(spacing: 0) {
            useAsTypedRow

            if !locationSearch.completions.isEmpty {
                Divider().opacity(0.35)
            }

            ForEach(Array(locationSearch.completions.prefix(4).enumerated()), id: \.element) { index, completion in
                Button {
                    selectLocation(completion)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppColor.primary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(completion.title)
                                .font(AppFont.caption.weight(.semibold))
                                .foregroundColor(AppColor.ink)
                                .lineLimit(1)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(AppFont.tiny)
                                    .foregroundColor(AppColor.inkFaint)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                if index < min(locationSearch.completions.count, 4) - 1 {
                    Divider().opacity(0.35)
                }
            }
        }
        .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }

    private var useAsTypedRow: some View {
        Button(action: useTypedLocation) {
            HStack(spacing: 8) {
                Image(systemName: "text.cursor")
                    .foregroundColor(AppColor.secondary)
                Text("Use \"\(trimmedLocation)\"")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
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

    // MARK: - Mood (single select)

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("HOW DID IT FEEL?")
            FlowLayout(spacing: 7) {
                ForEach(MemoryMood.allCases) { m in
                    moodOptionCard(m)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moodOptionCard(_ m: MemoryMood) -> some View {
        let selected = mood == m
        return Button {
            Haptics.selection()
            mood = m
        } label: {
            HStack(spacing: 4) {
                Text(m.emoji)
                    .font(.system(size: selected ? 14 : 13))
                    .frame(width: 17)

                Text(m.label)
                    .font(.clash(10, weight: selected ? .bold : .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .foregroundColor(selected ? .white : AppColor.ink)
            .padding(.horizontal, 8)
            .frame(width: 76, height: 36)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? AppGradient.hero : AppGradient.glass)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.86) : Color.white.opacity(0.58),
                            lineWidth: selected ? 1.5 : 1)
            )
            .shadow(
                color: selected ? AppColor.primary.opacity(0.3) : .black.opacity(0.04),
                radius: selected ? 5 : 3,
                y: selected ? 2 : 1
            )
            .scaleEffect(selected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .pressableScale(0.96)
    }

    // MARK: - Memorable tags (free-form, multi-select)

    private var memorableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                sectionLabel("WHAT MADE IT MEMORABLE?")
                if !memorableTags.isEmpty {
                    Text("\(memorableTags.count)")
                        .font(AppFont.tiny)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppColor.secondary))
                }
                Spacer()
                compactMemorableInput
            }

            if memorableTags.isEmpty {
                memorableEmptyRow
            } else {
                FlowLayout(spacing: 10) {
                    ForEach(memorableTags, id: \.self) { tag in
                        memorableSelectedChip(tag)
                    }
                }
            }

            memorableSuggestions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactMemorableInput: some View {
        HStack(spacing: 6) {
            TextField("Add", text: $memorableTagSearchText)
                .font(AppFont.caption)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .lineLimit(1)
                .frame(width: 80)
                .onSubmit { addMemorableFromSearch() }

            Button {
                addMemorableFromSearch()
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

    private var memorableEmptyRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("Pick a few — or add your own above")
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
    }

    private func memorableSelectedChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .fontWeight(.semibold)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Button {
                withAnimation(AppAnimation.snappy) {
                    memorableTags.removeAll { $0 == tag }
                }
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

    private var memorableSuggestions: some View {
        let options = MemorableReasonDefault.allLabels.filter { option in
            !memorableTags.contains { $0.caseInsensitiveCompare(option) == .orderedSame }
        }

        return VStack(alignment: .leading, spacing: 8) {
            if !options.isEmpty {
                Text("SUGGESTED REASONS")
                    .font(AppFont.tiny)
                    .foregroundColor(AppColor.inkMuted)
                    .padding(.leading, 4)

                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { tag in
                        Button {
                            addMemorableSuggested(tag)
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

    private func addMemorableFromSearch() {
        let trimmed = memorableTagSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !memorableTags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        else { return }
        withAnimation(AppAnimation.bouncy) {
            memorableTags.append(trimmed)
        }
        memorableTagSearchText = ""
        Haptics.success()
    }

    private func addMemorableSuggested(_ tag: String) {
        guard !memorableTags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { return }
        withAnimation(AppAnimation.bouncy) {
            memorableTags.append(tag)
        }
        Haptics.selection()
    }

    // MARK: - Best bite

    private var bestBiteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("THE BEST BITE")
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .foregroundColor(AppColor.accent)
                TextField("What was the bite you'd want to taste again?", text: $bestBite)
                    .font(.clash(15))
                    .autocorrectionDisabled(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .fieldSurface()
        }
    }

    // MARK: - People

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("WHO WAS THERE?")
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
                    if participants.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2")
                            Text("Tap + to tag the people you were with")
                        }
                        .font(.clash(12, weight: .medium))
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
                        ForEach(participants, id: \.self) { friendID in
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    AvatarView(
                                        avatar: friendAvatarImage(for: friendID),
                                        initials: friendName(for: friendID),
                                        size: 60,
                                        showRing: true
                                    )
                                    Button {
                                        withAnimation(AppAnimation.snappy) {
                                            participants.removeAll { $0 == friendID }
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
                                Text(friendName(for: friendID))
                                    .font(.clash(11, weight: .medium))
                                    .foregroundColor(AppColor.ink)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("A SHORT NOTE")
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("How did it taste? What stayed with you?")
                        .font(.clash(15))
                        .foregroundColor(AppColor.inkFaint)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $note)
                    .font(.clash(15))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(minHeight: 120)
            }
            .fieldSurface()
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.clash(11, weight: .semibold))
            .tracking(1.2)
            .foregroundColor(AppColor.inkMuted)
            .padding(.leading, 4)
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBite  = bestBite.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote  = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLoc   = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedLocation: String? = trimmedLoc.isEmpty ? nil : trimmedLoc
        let authorID = Auth.auth().currentUser?.uid ?? ""

        // When editing: keep original id/albumId/createdAt/reactions/capturedById.
        // When creating: build a fresh Memory in the current album.
        let memory: Memory
        if let original = memoryToEdit {
            memory = Memory(
                id: original.id,
                albumId: original.albumId,
                title: trimmedTitle.isEmpty ? original.title : trimmedTitle,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                imageURLs: original.imageURLs,
                photoData: photoData,
                location: resolvedLocation,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                capturedById: original.capturedById,
                reactions: original.reactions,
                mood: mood,
                bestBite: trimmedBite.isEmpty ? nil : trimmedBite,
                memorableTags: memorableTags,
                participantIds: participants,
                date: date,
                createdAt: original.createdAt,
                updatedAt: Date()
            )
        } else {
            memory = Memory(
                albumId: album.id,
                title: trimmedTitle.isEmpty ? "Untitled meal" : trimmedTitle,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                photoData: photoData,
                location: resolvedLocation,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                capturedById: authorID,
                mood: mood,
                bestBite: trimmedBite.isEmpty ? nil : trimmedBite,
                memorableTags: memorableTags,
                participantIds: participants,
                date: date
            )
        }

        Haptics.success()
        onSave(memory)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddMemoryView(
            album: Album(
                title: "PARK",
                ownerId: "jisu",
                tags: ["Picnic", "Outdoor"],
                location: "Centennial Park, Sydney"
            )
        )
        .environmentObject(LoginViewModel())
    }
}
