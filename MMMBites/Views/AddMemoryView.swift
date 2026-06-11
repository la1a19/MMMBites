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
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

private enum MemoryFieldLimits {
    static let title = 50
    static let bestBite = 80
    static let note = 400
    static let tag = 20
}

struct AddMemoryView: View {
    let album: Album
    let memoryToEdit: Memory?
    let existingMemories: [Memory]
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
    @State private var showPhotoSourceDialog = false
    @State private var showPhotoLibraryPicker = false
    @State private var showCameraPicker = false
    @State private var showCameraPermissionAlert = false

    // Real friends loaded from Firestore for the picker / display.
    @State private var friendUsers: [User] = []
    @State private var isLoadingFriends = false

    private var isEditing: Bool { memoryToEdit != nil }

    init(
        album: Album,
        memoryToEdit: Memory? = nil,
        existingMemories: [Memory] = [],
        onSave: @escaping (Memory) -> Void = { _ in }
    ) {
        self.album = album
        self.memoryToEdit = memoryToEdit
        self.existingMemories = existingMemories
        self.onSave = onSave

        _title             = State(initialValue: memoryToEdit?.title ?? "")
        _mood              = State(initialValue: memoryToEdit?.mood)
        _memorableTags     = State(initialValue: memoryToEdit?.memorableTags ?? [])
        _bestBite          = State(initialValue: memoryToEdit?.bestBite ?? "")
        _note              = State(initialValue: memoryToEdit?.note ?? "")
        _participants      = State(initialValue: memoryToEdit?.participantIds ?? [])
        _date              = State(initialValue: memoryToEdit?.date ?? Date())
        _photoData         = State(initialValue: memoryToEdit?.photoData ?? [])
        _location          = State(initialValue: memoryToEdit?.location ?? "")
        _selectedLatitude  = State(initialValue: memoryToEdit?.latitude)
        _selectedLongitude = State(initialValue: memoryToEdit?.longitude)
        _showOptionalDetails = State(initialValue: memoryToEdit != nil)
    }

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)

            ScrollView {
                memoryFormContent
                    .padding(AppSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(isEditing ? "Edit Meal Memory" : "Start a Meal Memory")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.clash(14, weight: .bold))
                        .foregroundColor(AppColor.ink)
                        .frame(width: 32, height: 32)
                        .glassCircleSurface()
                }
            }
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
        .task(id: album.friendIds + [album.ownerId]) {
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
        .confirmationDialog("Add a photo", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            Button("Take Photo") {
                requestCameraAccessForPhoto()
            }
            Button("Choose from Library") {
                showPhotoLibraryPicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(
            isPresented: $showPhotoLibraryPicker,
            selection: $pickerItems,
            maxSelectionCount: max(1, 5 - photoData.count),
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraCaptureView { data in
                guard let data else { return }
                withAnimation(AppAnimation.snappy) {
                    if photoData.count < 5 {
                        photoData.append(data)
                    }
                }
                Haptics.success()
            }
            .ignoresSafeArea()
        }
        .alert("Camera access needed", isPresented: $showCameraPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                openAppSettings()
            }
        } message: {
            Text("Allow camera access in Settings to take photos for your meal memories.")
        }
    }

    private var memoryFormContent: some View {
        VStack(spacing: AppSpacing.xl) {
            groupHeader("THE BASICS", subtitle: "What, when, and where")
                .bounceOnAppear()

            titleField
                .bounceOnAppear(delay: 0.02)

            photosField
                .bounceOnAppear(delay: 0.04)

            dateLocationSection
                .bounceOnAppear(delay: 0.06)

            groupHeader("THE STORY", subtitle: "What made it stick with you")
                .padding(.top, AppSpacing.s)
                .bounceOnAppear(delay: 0.08)

            moodSection
                .bounceOnAppear(delay: 0.1)

            bestBiteSection
                .bounceOnAppear(delay: 0.12)

            memorableSection
                .bounceOnAppear(delay: 0.14)

            peopleSection
                .bounceOnAppear(delay: 0.16)

            optionalDetailsToggle
                .bounceOnAppear(delay: 0.18)

            optionalNoteSection

            PrimaryButton(
                title: isEditing ? "Save changes" : "Save Memory",
                icon: isEditing ? "checkmark" : "sparkles"
            ) {
                save()
            }
            .padding(.top, 4)
            .bounceOnAppear(delay: 0.3)
        }
    }

    private var dateLocationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .top, spacing: AppSpacing.m) {
                dateSection
                locationSection
            }

            if showDatePicker {
                datePickerPopup
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let suggestion = locationSuggestionMemory {
                locationHintCard(for: suggestion)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppAnimation.snappy, value: locationSuggestionMemory?.id)
    }

    @ViewBuilder
    private var optionalNoteSection: some View {
        if showOptionalDetails {
            noteSection
                .transition(.opacity.combined(with: .move(edge: .top)))
                .bounceOnAppear(delay: 0.2)
        }
    }

    // MARK: - Friend loading

    private func loadFriends() async {
        // The picker is constrained to people who are part of THIS album:
        // album owner + album.friendIds. Even if I'm friends with someone
        // outside the album, they can't be tagged in a memory inside it.
        var pickerIDs = Set(album.friendIds)
        pickerIDs.insert(album.ownerId)
        if let currentUserID = authViewModel.currentUser?.id {
            pickerIDs.remove(currentUserID)
        }

        guard !pickerIDs.isEmpty else {
            friendUsers = []
            return
        }

        isLoadingFriends = true
        defer { isLoadingFriends = false }

        let database = Firestore.firestore()
        var loaded: [User] = []
        for chunk in Array(pickerIDs).chunked(into: 30) {
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
                Button {
                    Haptics.tap()
                    showPhotoSourceDialog = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.clash(15, weight: .semibold))
                        Text("Add a few photos, or take one now")
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

                        Button {
                            Haptics.tap()
                            showPhotoSourceDialog = true
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.clash(18, weight: .semibold))
                                Text("Add")
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

    private func requestCameraAccessForPhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showPhotoLibraryPicker = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraPicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        showCameraPicker = true
                    } else {
                        Haptics.warning()
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            Haptics.warning()
            showCameraPermissionAlert = true
        @unknown default:
            Haptics.warning()
            showCameraPermissionAlert = true
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func loadPickedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }

        await MainActor.run {
            withAnimation(AppAnimation.snappy) {
                let remainingSlots = max(0, 5 - photoData.count)
                photoData.append(contentsOf: loaded.prefix(remainingSlots))
            }
            pickerItems = []
            if !loaded.isEmpty {
                Haptics.success()
            }
        }
    }

    // MARK: - Title

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                sectionLabel("WHAT TO CALL THIS MEMORY")
                Spacer()
                counterLabel(count: title.count, limit: MemoryFieldLimits.title)
            }
            HStack(spacing: 8) {
                TextField("e.g. Sunday roast with the girls", text: $title)
                    .font(.clash(20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled(true)
                    .textContentType(nil)
                    .onChange(of: title) { _, newValue in
                        if newValue.count > MemoryFieldLimits.title {
                            title = String(newValue.prefix(MemoryFieldLimits.title))
                        }
                    }
                FieldClearButton(text: $title)
            }
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
                    Text(showOptionalDetails ? "Hide note" : "Add a note")
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.ink)
                    Text("Anything else you want to remember")
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
                        .font(.clash(12, weight: .semibold))
                        .foregroundColor(AppColor.secondary)
                    Text(date, style: .date)
                        .font(.clash(12, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 22)
                .pillSurface()
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var datePickerPopup: some View {
        DatePicker("Memory date", selection: $date, displayedComponents: .date)
            .datePickerStyle(.graphical)
            .tint(AppColor.primary)
            .padding(8)
            .frame(maxWidth: .infinity)
            .glassCard(radius: AppRadius.m, padding: 0)
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("LOCATION")

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.clash(12, weight: .semibold))
                    .foregroundColor(AppColor.primary)
                TextField("e.g. Bills, Bondi", text: $location)
                    .font(.clash(12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                FieldClearButton(text: $location)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 22)
            .pillSurface()

            if isLocationFocused && shouldShowLocationSuggestions {
                locationSuggestions
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Location hint (same place suggestion)

    private var locationSuggestionMemory: Memory? {
        let normalized = location
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard normalized.count >= 2 else { return nil }

        let editingID = memoryToEdit?.id

        let matches = existingMemories.filter { memory in
            guard memory.id != editingID,
                  let loc = memory.location?.lowercased(),
                  !loc.isEmpty else { return false }
            return loc.contains(normalized) || normalized.contains(loc)
        }
        return matches.sorted { $0.date > $1.date }.first
    }

    private func locationHintCard(for memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.clash(11, weight: .bold))
                    .foregroundStyle(AppGradient.heroText)
                Text("YOU'VE BEEN HERE BEFORE")
                    .font(.clash(10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(AppGradient.heroText)
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Text(timeAgoLabel(from: memory.date))
                    .font(.clash(13, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text("·")
                    .foregroundColor(AppColor.inkFaint)
                Text(memory.title)
                    .font(.clash(13, weight: .medium))
                    .foregroundColor(AppColor.inkMuted)
                    .lineLimit(1)
            }

            if memory.mood != nil || !(memory.bestBite ?? "").isEmpty {
                HStack(spacing: 8) {
                    if let mood = memory.mood {
                        HStack(spacing: 4) {
                            Text(mood.emoji).font(.system(size: 12))
                            Text("felt \(mood.label.lowercased())")
                                .font(.clash(11, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                    }
                    if let bite = memory.bestBite, !bite.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.clash(9, weight: .semibold))
                                .foregroundColor(AppColor.accent)
                            Text(bite)
                                .font(.clash(11, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                .stroke(AppColor.primary.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }

    private func timeAgoLabel(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        switch days {
        case ..<1:    return "earlier today"
        case 1:       return "yesterday"
        case 2..<7:   return "\(days) days ago"
        case 7..<14:  return "a week ago"
        case 14..<30: return "\(days / 7) weeks ago"
        case 30..<60: return "a month ago"
        case 60..<365:
            let months = days / 30
            return "\(months) months ago"
        default:
            let years = days / 365
            return years == 1 ? "a year ago" : "\(years) years ago"
        }
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
            HStack(spacing: 5) {
                Text(m.emoji)
                    .font(.system(size: selected ? 13 : 12))
                    .frame(width: 15)

                Text(m.label)
                    .font(.clash(11, weight: selected ? .bold : .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(selected ? .white : AppColor.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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
                .textContentType(nil)
                .textInputAutocapitalization(.words)
                .lineLimit(1)
                .frame(width: 80)
                .onSubmit { addMemorableFromSearch() }
                .onChange(of: memorableTagSearchText) { _, newValue in
                    if newValue.count > MemoryFieldLimits.tag {
                        memorableTagSearchText = String(newValue.prefix(MemoryFieldLimits.tag))
                    }
                }

            FieldClearButton(text: $memorableTagSearchText)

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
            Text("Pick a few, or add your own")
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
            HStack(alignment: .firstTextBaseline) {
                sectionLabel("THE BEST BITE")
                Spacer()
                counterLabel(count: bestBite.count, limit: MemoryFieldLimits.bestBite)
            }
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .foregroundColor(AppColor.accent)
                TextField("What was the bite you'd want to taste again?", text: $bestBite)
                    .font(.clash(15))
                    .autocorrectionDisabled(true)
                    .textContentType(nil)
                    .onChange(of: bestBite) { _, newValue in
                        if newValue.count > MemoryFieldLimits.bestBite {
                            bestBite = String(newValue.prefix(MemoryFieldLimits.bestBite))
                        }
                    }
                FieldClearButton(text: $bestBite)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .fieldSurface()
        }
    }

    // MARK: - People

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("WHO WAS THERE?")

            if participants.isEmpty {
                Button {
                    Haptics.tap()
                    showFriendPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.clash(15, weight: .semibold))
                        Text("Tap to add who you were with")
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
                    HStack(spacing: AppSpacing.m) {
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

                        Button {
                            Haptics.tap()
                            showFriendPicker = true
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: "person.badge.plus")
                                    .font(.clash(18, weight: .semibold))
                                Text("Add")
                                    .font(AppFont.tiny)
                            }
                            .foregroundColor(AppColor.inkMuted)
                            .frame(width: 64, height: 84)
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
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                sectionLabel("A SHORT NOTE")
                Spacer()
                counterLabel(count: note.count, limit: MemoryFieldLimits.note)
            }
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
                    .autocorrectionDisabled(true)
                    .textContentType(nil)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(minHeight: 120)
                    .onChange(of: note) { _, newValue in
                        if newValue.count > MemoryFieldLimits.note {
                            note = String(newValue.prefix(MemoryFieldLimits.note))
                        }
                    }
            }
            .overlay(alignment: .topTrailing) {
                FieldClearButton(text: $note)
                    .padding(.top, 10)
                    .padding(.trailing, 10)
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

    @ViewBuilder
    private func counterLabel(count: Int, limit: Int) -> some View {
        // Only show the counter once the user is approaching the limit,
        // otherwise it's visual noise.
        let threshold = max(1, limit - 10)
        if count >= threshold {
            Text("\(count)/\(limit)")
                .font(.clash(10, weight: .semibold))
                .foregroundColor(count >= limit ? AppColor.primary : AppColor.inkMuted)
                .padding(.trailing, 4)
        }
    }

    private func groupHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.clash(13, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(AppGradient.heroText)
                Rectangle()
                    .fill(AppColor.primary.opacity(0.25))
                    .frame(height: 1)
            }
            Text(subtitle)
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                friendMemorableTags: [],
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

private struct CameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data?) -> Void
        private var didFinish = false

        init(onCapture: @escaping (Data?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard !didFinish else { return }
            didFinish = true

            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            let data = image?.jpegData(compressionQuality: 0.9)
            picker.dismiss(animated: true) { [onCapture] in
                onCapture(data)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            guard !didFinish else { return }
            didFinish = true
            picker.dismiss(animated: true) { [onCapture] in
                onCapture(nil)
            }
        }
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
