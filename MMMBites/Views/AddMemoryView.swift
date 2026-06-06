//
//  AddMemoryView.swift
//  MMMBites
//
//  Form for recording a meal memory — mood, best bite, who was there,
//  and what made it memorable.
//

import SwiftUI
import PhotosUI

struct AddMemoryView: View {
    let album: Album
    let memoryToEdit: Memory?
    var onSave: (Memory) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var mood: MemoryMood?
    @State private var memorableReasons: Set<MemorableReason>
    @State private var bestBite: String
    @State private var note: String
    @State private var participants: [String]
    @State private var date: Date
    @State private var showFriendPicker = false
    @State private var showDatePicker = false

    // Photo picking
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photoData: [Data]

    private let allFriends = ["Judy", "Mira", "Alex", "Sam", "Lila", "Nina", "Theo", "Ben"]

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
        _memorableReasons  = State(initialValue: Set(memoryToEdit?.memorableReasons ?? []))
        _bestBite          = State(initialValue: memoryToEdit?.bestBite ?? "")
        _note              = State(initialValue: memoryToEdit?.note ?? "")
        _participants      = State(initialValue: memoryToEdit?.participantIds ?? [])
        _date              = State(initialValue: memoryToEdit?.date ?? Date())
        _photoData         = State(initialValue: memoryToEdit?.photoData ?? [])
    }

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)

            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    photosField
                        .bounceOnAppear()

                    titleField
                        .bounceOnAppear(delay: 0.03)

                    dateSection
                        .bounceOnAppear(delay: 0.04)

                    moodSection
                        .bounceOnAppear(delay: 0.05)

                    memorableSection
                        .bounceOnAppear(delay: 0.1)

                    bestBiteSection
                        .bounceOnAppear(delay: 0.15)

                    peopleSection
                        .bounceOnAppear(delay: 0.2)

                    noteSection
                        .bounceOnAppear(delay: 0.25)

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
        .animation(AppAnimation.snappy, value: mood)
        .animation(AppAnimation.snappy, value: memorableReasons)
        .animation(AppAnimation.snappy, value: participants)
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(
                allFriends: allFriends,
                selectedFriends: $participants
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Photos

    private var photosField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("PHOTOS")
                Spacer()
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 5,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.clash(12, weight: .bold))
                        Text(photoData.isEmpty ? "Add photos" : "Change")
                            .font(.clash(12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppGradient.hero))
                    .shadow(color: AppColor.primary.opacity(0.35), radius: 6, y: 3)
                }
            }

            if photoData.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                    Text("Pick a few photos to remember this meal by")
                }
                .font(.clash(12, weight: .medium))
                .foregroundColor(AppColor.inkFaint)
                .padding(.vertical, 22)
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
                .background(Color.white.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
    }

    // MARK: - Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("WHEN WAS THIS MEMORY?")

            Button {
                Haptics.tap()
                withAnimation(AppAnimation.snappy) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColor.secondary)
                    Text(date, style: .date)
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                        .font(.clash(11, weight: .bold))
                        .foregroundColor(AppColor.inkFaint)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.85), in: Capsule(style: .continuous))
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }
            .buttonStyle(.plain)

            if showDatePicker {
                DatePicker("Memory date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppColor.primary)
                    .padding(8)
                    .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Mood (single select)

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOW DID IT FEEL?")
            FlowLayout(spacing: 8) {
                ForEach(MemoryMood.allCases) { m in
                    moodChip(m)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moodChip(_ m: MemoryMood) -> some View {
        let selected = mood == m
        return Button {
            Haptics.selection()
            mood = selected ? nil : m
        } label: {
            HStack(spacing: 6) {
                Text(m.emoji)
                    .font(.system(size: 16))
                Text(m.label)
                    .font(.clash(14, weight: .semibold))
            }
            .foregroundColor(selected ? .white : AppColor.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(selected ? AppColor.primary : Color.white.opacity(0.85))
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: selected ? AppColor.primary.opacity(0.35) : .black.opacity(0.05),
                    radius: selected ? 8 : 4, y: 2)
            .scaleEffect(selected ? 1.0 : 0.97)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Memorable reason (multi-select)

    private var memorableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("WHAT MADE IT MEMORABLE?")
            FlowLayout(spacing: 8) {
                ForEach(MemorableReason.allCases) { r in
                    reasonChip(r)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reasonChip(_ r: MemorableReason) -> some View {
        let selected = memorableReasons.contains(r)
        return Button {
            Haptics.selection()
            if selected {
                memorableReasons.remove(r)
            } else {
                memorableReasons.insert(r)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: r.icon)
                    .font(.clash(12, weight: .semibold))
                Text(r.label)
                    .font(.clash(14, weight: .semibold))
            }
            .foregroundColor(selected ? .white : AppColor.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(selected ? AppColor.secondary : Color.white.opacity(0.85))
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: selected ? AppColor.secondary.opacity(0.35) : .black.opacity(0.05),
                    radius: selected ? 8 : 4, y: 2)
        }
        .buttonStyle(.plain)
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
            .background(Color.white.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
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
                        ForEach(participants, id: \.self) { friend in
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    AvatarView(initials: friend, size: 60, showRing: true)
                                    Button {
                                        withAnimation(AppAnimation.snappy) {
                                            participants.removeAll { $0 == friend }
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
            .background(Color.white.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
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

        // When editing: keep original id/albumId/createdAt/reactions/capturedById/coords.
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
                location: original.location,
                latitude: original.latitude,
                longitude: original.longitude,
                capturedById: original.capturedById,
                reactions: original.reactions,
                mood: mood,
                bestBite: trimmedBite.isEmpty ? nil : trimmedBite,
                memorableReasons: Array(memorableReasons),
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
                location: album.location,
                capturedById: "Jisu",
                mood: mood,
                bestBite: trimmedBite.isEmpty ? nil : trimmedBite,
                memorableReasons: Array(memorableReasons),
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
                tags: ["Tree", "Picnic"],
                location: "Centennial Park, Sydney"
            )
        )
    }
}
