//
//  MemoryDetailSheets.swift
//  MMMBites
//
//  Standalone sheets used by MemoryDetailView: emoji reaction picker
//  and note editor. Kept separate to keep MemoryDetailView focused on
//  layout rather than modal plumbing.
//

import SwiftUI

// MARK: - Emoji reaction picker

private struct EmojiReactionCategory: Identifiable {
    let name: String
    let icon: String
    let emojis: [String]
    var id: String { name }
}

struct MemoryEmojiPickerSheet: View {
    let onPick: (String) -> Void

    @State private var selectedCategory = "Smileys"
    @Environment(\.dismiss) private var dismiss

    private let categories: [EmojiReactionCategory] = [
        EmojiReactionCategory(
            name: "Smileys",
            icon: "😀",
            emojis: ["😀", "😃", "😄", "😁", "😆", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😍", "🥰", "😘", "😋", "😛", "😜", "🤪", "😎", "🤓", "🥹", "😭", "🫠", "😳", "😤", "😌", "😴", "🤯"]
        ),
        EmojiReactionCategory(
            name: "Food",
            icon: "🍽️",
            emojis: ["🍽️", "🍕", "🍔", "🍟", "🌭", "🍗", "🍖", "🍜", "🍝", "🍣", "🍙", "🍚", "🍛", "🍤", "🥟", "🥗", "🥪", "🥐", "🍞", "🧀", "🍰", "🧁", "🍦", "🍓", "🍇", "🍉", "🍌", "🍎", "☕️", "🧋", "🍵", "🌶️"]
        ),
        EmojiReactionCategory(
            name: "Mood",
            icon: "✨",
            emojis: ["✨", "🫶", "💖", "💕", "💗", "💫", "🌟", "🔥", "😍", "🥹", "😂", "😌", "🥰", "😭", "🤩", "😎"]
        ),
        EmojiReactionCategory(
            name: "Places",
            icon: "🧺",
            emojis: ["🧺", "🌳", "🌊", "🌇", "🏙️", "🏠", "🏕️", "🪴", "☀️", "🌙", "🌈", "🍃"]
        ),
        EmojiReactionCategory(
            name: "Celebration",
            icon: "🎉",
            emojis: ["🎉", "🥳", "🎂", "🎁", "🎈", "🕯️", "🍰", "✨", "🌟", "💖", "🫶"]
        )
    ]

    private var currentEmojis: [String] {
        categories.first { $0.name == selectedCategory }?.emojis ?? categories[0].emojis
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { category in
                                Button {
                                    Haptics.selection()
                                    withAnimation(AppAnimation.snappy) {
                                        selectedCategory = category.name
                                    }
                                } label: {
                                    Text(category.icon)
                                        .font(.clash(22))
                                        .frame(width: 42, height: 36)
                                        .background(
                                            Capsule().fill(
                                                selectedCategory == category.name
                                                ? AppColor.secondary.opacity(0.25)
                                                : Color.white.opacity(0.82)
                                            )
                                        )
                                        .overlay(
                                            Capsule().stroke(
                                                selectedCategory == category.name
                                                ? AppColor.secondary.opacity(0.65)
                                                : Color.white.opacity(0.6),
                                                lineWidth: selectedCategory == category.name ? 1.5 : 1
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }

                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(42), spacing: 8), count: 6),
                            spacing: 10
                        ) {
                            ForEach(currentEmojis, id: \.self) { emoji in
                                Button {
                                    onPick(emoji)
                                } label: {
                                    Text(emoji)
                                        .font(.clash(24))
                                        .frame(width: 42, height: 42)
                                        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .pressableScale(0.92)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
                .padding(.top, AppSpacing.m)
            }
            .navigationTitle("Add Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.tap()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Note editor

struct MemoryNoteEditorSheet: View {
    let isEdit: Bool
    let onSave: (String?) -> Void

    @State private var draft: String
    @Environment(\.dismiss) private var dismiss

    init(initialNote: String?, isEdit: Bool, onSave: @escaping (String?) -> Void) {
        self.isEdit = isEdit
        self.onSave = onSave
        _draft = State(initialValue: initialNote ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                VStack(spacing: AppSpacing.m) {
                    ZStack(alignment: .topLeading) {
                        if draft.isEmpty {
                            Text("Write what made this moment special…")
                                .font(AppFont.body)
                                .foregroundColor(AppColor.inkFaint)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $draft)
                            .font(AppFont.body)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(minHeight: 200)
                    }
                    .fieldSurface()

                    Spacer(minLength: 0)
                }
                .padding(AppSpacing.xl)
            }
            .navigationTitle(isEdit ? "Edit Note" : "Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        Haptics.tap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmed.isEmpty ? nil : trimmed)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
