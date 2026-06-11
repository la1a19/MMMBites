//
//  SettingsView.swift
//  MMMBites
//
//  Presented from the top-right user menu → "Settings".
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Persisted preferences
    @AppStorage("pref.hapticFeedback")      private var hapticFeedback: Bool = true
    @AppStorage("pref.memoryReminders")     private var memoryReminders: Bool = true
    @AppStorage("pref.appearance")          private var appearanceRaw: String = AppearanceMode.system.rawValue

    @State private var showFeedbackSheet = false
    @State private var navigateToPrivacyPolicy = false
    
    
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        preferencesSection
                            .bounceOnAppear()

                        appearanceSection
                            .bounceOnAppear(delay: 0.05)

                        aboutSection
                            .bounceOnAppear(delay: 0.1)

                        Text("MMMBites · \(appVersion)")
                            .font(.clash(11, weight: .medium))
                            .foregroundColor(AppColor.inkFaint)
                            .padding(.top, AppSpacing.s)
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Settings")
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
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $navigateToPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - PREFERENCES

    private var preferencesSection: some View {
        sectionGroup(title: "PREFERENCES") {
            toggleRow(icon: "iphone.radiowaves.left.and.right",
                      tint: AppColor.primary,
                      title: "Haptic feedback",
                      subtitle: nil,
                      isOn: $hapticFeedback)

            divider

            toggleRow(icon: "bell.fill",
                      tint: AppColor.secondary,
                      title: "Memory reminders",
                      subtitle: nil,
                      isOn: $memoryReminders)
        }
    }

    // MARK: - APPEARANCE

    private var appearanceSection: some View {
        sectionGroup(title: "APPEARANCE") {
            HStack(spacing: AppSpacing.m) {
                iconBadge(icon: "paintpalette.fill", tint: AppColor.secondary)
                Text("Theme")
                    .font(.clash(15, weight: .medium))
                    .foregroundColor(AppColor.ink)
                Spacer()
            }
            .padding(.vertical, 8)

            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    appearanceChip(mode)
                }
            }
            .padding(.top, 2)
        }
    }

    private func appearanceChip(_ mode: AppearanceMode) -> some View {
        let selected = appearanceRaw == mode.rawValue
        return Button {
            Haptics.selection()
            appearanceRaw = mode.rawValue
        } label: {
            Text(mode.label)
                .font(.clash(13, weight: .semibold))
                .foregroundColor(selected ? .white : AppColor.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(selected ? AppColor.primary : Color.white.opacity(0.85))
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: selected ? AppColor.primary.opacity(0.3) : .black.opacity(0.04),
                        radius: selected ? 6 : 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - ABOUT

    private var aboutSection: some View {
        sectionGroup(title: "ABOUT") {
            navRow(icon: "envelope.fill",
                   tint: AppColor.primary,
                   title: "Send feedback",
                   action: {
                       Haptics.tap()
                       showFeedbackSheet = true
                   })
            divider
            navRow(icon: "lock.shield.fill",
                   tint: AppColor.secondary,
                   title: "Privacy policy",
                   action: {
                       Haptics.tap()
                       navigateToPrivacyPolicy = true
                   })
            divider
            navRow(icon: "doc.text.fill",
                   tint: AppColor.accent,
                   title: "Terms of service",
                   action: { Haptics.tap() })
        }
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func sectionGroup<Content: View>(title: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.clash(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppColor.inkMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, AppSpacing.s)
            .background(AppGradient.glass,
                        in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.inkFaint.opacity(0.15))
            .frame(height: 1)
            .padding(.leading, 50)
    }

    private func iconBadge(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.clash(13, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 32, height: 32)
            .background(Circle().fill(tint.opacity(0.18)))
    }

    private func toggleRow(icon: String,
                           tint: Color,
                           title: String,
                           subtitle: String?,
                           isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.m) {
            iconBadge(icon: icon, tint: tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.clash(15, weight: .medium))
                    .foregroundColor(AppColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.clash(12, weight: .regular))
                        .foregroundColor(AppColor.inkFaint)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColor.primary)
                .onChange(of: isOn.wrappedValue) { _, _ in
                    Haptics.selection()
                }
        }
        .padding(.vertical, 10)
    }

    private func navRow(icon: String,
                        tint: Color,
                        title: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.m) {
                iconBadge(icon: icon, tint: tint)
                Text(title)
                    .font(.clash(15, weight: .medium))
                    .foregroundColor(AppColor.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.clash(12, weight: .semibold))
                    .foregroundColor(AppColor.inkFaint)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feedback sheet

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message: String = ""

    var body: some View {
        ZStack {
            AppBackground(variant: .warm)
            VStack(spacing: AppSpacing.l) {
                VStack(spacing: 4) {
                    Text("Send feedback")
                        .font(.clash(20, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Text("We read every note 🍳")
                        .font(.clash(13, weight: .regular))
                        .foregroundColor(AppColor.inkMuted)
                }
                .padding(.top, AppSpacing.l)

                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("What's on your mind?")
                            .font(.clash(15))
                            .foregroundColor(AppColor.inkFaint)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $message)
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

                PrimaryButton(title: "Send", icon: "paperplane.fill") {
                    Haptics.success()
                    dismiss()
                }
                Spacer()
            }
            .padding(AppSpacing.xl)
        }
    }
}

#Preview {
    SettingsView()
}
