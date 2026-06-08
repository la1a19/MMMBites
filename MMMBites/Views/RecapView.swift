//
//  RecapView.swift
//  MMMBites
//
//  Spotify-Wrapped-style summary screen. Shows top mood, top buddy,
//  top location, top memorable reason, and a couple of bestBite spotlights
//  over a selectable time window (month / year / all time).
//

import SwiftUI

struct RecapView: View {
    let memories: [Memory]
    let friendNamesByID: [String: String]

    @Environment(\.dismiss) private var dismiss
    @State private var period: RecapPeriod = .year

    enum RecapPeriod: String, CaseIterable, Identifiable {
        case month, year, all
        var id: String { rawValue }
        var label: String {
            switch self {
            case .month: return "Month"
            case .year:  return "Year"
            case .all:   return "All time"
            }
        }
    }

    private var filteredMemories: [Memory] {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .month:
            let comp = calendar.dateComponents([.year, .month], from: now)
            return memories.filter {
                let c = calendar.dateComponents([.year, .month], from: $0.date)
                return c.year == comp.year && c.month == comp.month
            }
        case .year:
            let year = calendar.component(.year, from: now)
            return memories.filter { calendar.component(.year, from: $0.date) == year }
        case .all:
            return memories
        }
    }

    private var heroSubtitle: String {
        let formatter = DateFormatter()
        switch period {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: Date()).uppercased()
        case .year:
            formatter.dateFormat = "yyyy"
            return "IN \(formatter.string(from: Date()))"
        case .all:
            return "SINCE THE START"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(variant: .warm)

                ScrollView {
                    VStack(spacing: AppSpacing.l) {
                        periodSelector

                        if filteredMemories.isEmpty {
                            emptyState
                        } else {
                            heroCard

                            if let mood = topMood {
                                statCard(
                                    leading: AnyView(Text(mood.mood.emoji).font(.system(size: 40))),
                                    label: "MOST FELT",
                                    value: mood.mood.label,
                                    subtitle: "\(mood.count) \(mood.count == 1 ? "time" : "times")"
                                )
                            }

                            if let buddy = topBuddy {
                                let name = friendNamesByID[buddy.userID] ?? "Friend"
                                statCard(
                                    leading: AnyView(
                                        AvatarView(initials: name, size: 56, showRing: true)
                                    ),
                                    label: "TOP FOOD BUDDY",
                                    value: name,
                                    subtitle: "\(buddy.count) \(buddy.count == 1 ? "memory" : "memories") together"
                                )
                            }

                            if let location = topLocation {
                                statCard(
                                    leading: AnyView(
                                        ZStack {
                                            Circle()
                                                .fill(AppColor.primary.opacity(0.18))
                                                .frame(width: 56, height: 56)
                                            Image(systemName: "mappin.and.ellipse")
                                                .font(.clash(22, weight: .bold))
                                                .foregroundStyle(AppGradient.hero)
                                        }
                                    ),
                                    label: "FAVOURITE SPOT",
                                    value: location.name,
                                    subtitle: "\(location.count) \(location.count == 1 ? "visit" : "visits")"
                                )
                            }

                            if let reason = topReason {
                                statCard(
                                    leading: AnyView(
                                        ZStack {
                                            Circle()
                                                .fill(AppColor.accent.opacity(0.22))
                                                .frame(width: 56, height: 56)
                                            Image(systemName: "sparkles")
                                                .font(.clash(22, weight: .bold))
                                                .foregroundStyle(AppGradient.hero)
                                        }
                                    ),
                                    label: "MOST MEMORABLE FOR",
                                    value: reason.label,
                                    subtitle: "\(reason.count) \(reason.count == 1 ? "memory" : "memories")"
                                )
                            }

                            if !bestBiteSpotlight.isEmpty {
                                spotlightSection
                            }
                        }
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Your Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Period selector

    private var periodSelector: some View {
        HStack(spacing: 6) {
            ForEach(RecapPeriod.allCases) { p in
                Button {
                    Haptics.selection()
                    withAnimation(AppAnimation.snappy) { period = p }
                } label: {
                    Text(p.label)
                        .font(.clash(12, weight: period == p ? .bold : .semibold))
                        .foregroundColor(period == p ? .white : AppColor.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(period == p ? AppGradient.hero : AppGradient.glass)
                        )
                        .overlay(
                            Capsule().stroke(
                                Color.white.opacity(period == p ? 0.85 : 0.6),
                                lineWidth: period == p ? 1.5 : 1
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(spacing: AppSpacing.s) {
            Text(heroSubtitle)
                .font(.clash(11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(AppGradient.hero)
            Text("\(filteredMemories.count)")
                .font(.clash(72, weight: .black))
                .foregroundStyle(AppGradient.hero)
            Text(filteredMemories.count == 1 ? "meal memory" : "meal memories")
                .font(.clash(16, weight: .semibold))
                .foregroundColor(AppColor.ink)
            Text("logged so far")
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.l)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }

    // MARK: - Stat card

    private func statCard(
        leading: AnyView,
        label: String,
        value: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: AppSpacing.m) {
            leading
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.clash(10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(AppGradient.hero)
                Text(value)
                    .font(.clash(20, weight: .bold))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.inkMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .frame(maxWidth: .infinity)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Spotlight (best bites)

    private var spotlightSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(spacing: 4) {
                Image(systemName: "quote.opening")
                    .font(.clash(11, weight: .bold))
                    .foregroundStyle(AppGradient.hero)
                Text("BITES THAT STAYED WITH YOU")
                    .font(.clash(10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(AppGradient.hero)
                Spacer(minLength: 0)
            }
            .padding(.leading, 4)

            ForEach(bestBiteSpotlight) { memory in
                spotlightCard(memory)
            }
        }
    }

    private func spotlightCard(_ memory: Memory) -> some View {
        let bite = memory.bestBite ?? ""
        return VStack(alignment: .leading, spacing: 8) {
            Text("\u{201C}\(bite)\u{201D}")
                .font(.clash(16, weight: .semibold))
                .foregroundColor(AppColor.ink)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if let mood = memory.mood {
                    Text(mood.emoji).font(.system(size: 11))
                    Text("·").foregroundColor(AppColor.inkFaint)
                }
                Text(memory.title)
                    .font(.clash(11, weight: .semibold))
                    .foregroundColor(AppColor.inkMuted)
                    .lineLimit(1)
                Text("·").foregroundColor(AppColor.inkFaint)
                Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.clash(11, weight: .medium))
                    .foregroundColor(AppColor.inkFaint)
            }
        }
        .padding(AppSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppGradient.glass, in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(AppGradient.glass)
                    .frame(width: 88, height: 88)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                Image(systemName: "sparkles")
                    .font(.clash(32, weight: .bold))
                    .foregroundStyle(AppGradient.hero)
            }
            Text("Nothing to recap yet")
                .font(AppFont.headline)
                .foregroundColor(AppColor.inkMuted)
            Text(emptyMessage)
                .font(AppFont.caption)
                .foregroundColor(AppColor.inkFaint)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .padding(.top, AppSpacing.xl)
    }

    private var emptyMessage: String {
        switch period {
        case .month: return "Log a meal memory this month — your recap will fill in."
        case .year:  return "Start saving memories — your year-end story builds itself."
        case .all:   return "Your collection is empty. Start by adding your first meal memory."
        }
    }

    // MARK: - Aggregations

    private var topMood: (mood: MemoryMood, count: Int)? {
        var counts: [MemoryMood: Int] = [:]
        for memory in filteredMemories {
            if let mood = memory.mood { counts[mood, default: 0] += 1 }
        }
        return counts.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }

    private var topBuddy: (userID: String, count: Int)? {
        var counts: [String: Int] = [:]
        for memory in filteredMemories {
            for id in memory.participantIds { counts[id, default: 0] += 1 }
        }
        return counts.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }

    private var topLocation: (name: String, count: Int)? {
        var counts: [String: Int] = [:]
        for memory in filteredMemories {
            let raw = (memory.location ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { continue }
            counts[raw, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }

    private var topReason: (label: String, count: Int)? {
        var counts: [String: Int] = [:]
        for memory in filteredMemories {
            for tag in memory.memorableTags {
                let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                counts[trimmed.lowercased(), default: 0] += 1
            }
        }
        return counts.max { $0.value < $1.value }.map { ($0.key.capitalized, $0.value) }
    }

    private var bestBiteSpotlight: [Memory] {
        let withBites = filteredMemories.filter {
            !($0.bestBite ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return Array(withBites.shuffled().prefix(2))
    }
}
