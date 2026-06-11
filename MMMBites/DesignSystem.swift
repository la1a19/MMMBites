//
//  DesignSystem.swift
//  MMMBites
//
//  Central design tokens, modifiers and helpers used across the app.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Brand palette

enum AppColor {
    // Brand palette — warm food-app tones (peach-coral + honey-apricot + cream).
    // Sampled from the AddAlbumView warm screen so every surface lives in the same family.
    static let primary    = Color(red: 233 / 255, green: 146 / 255, blue: 117 / 255)   // #E99275  soft peach-coral
    static let secondary  = Color(red: 246 / 255, green: 209 / 255, blue: 175 / 255)   // #F6D1AF  honey apricot
    static let background = Color(red: 255 / 255, green: 244 / 255, blue: 232 / 255)   // #FFF4E8  warm cream
    static let accent     = primary

    // Surfaces
    static let surface    = background
    static let surfaceMuted = background.opacity(0.55)
    static let surfaceGlass = background.opacity(0.7)

    // Ink (text) — warmer, darker tones for readable contrast on cream surfaces
    static let ink        = Color(red: 0.12, green: 0.09, blue: 0.07)                  // #1F1812  warm near-black
    static let inkMuted   = Color(red: 0.34, green: 0.28, blue: 0.23)                  // #57483B  warm brown-gray
    static let inkFaint   = Color(red: 0.55, green: 0.47, blue: 0.40)                  // #8C7866  readable warm gray

    // Pastel background stops — every stop comes from primary/secondary so
    // all screens share the same peach + honey + cream family.
    static let bgMint     = secondary                  // honey apricot
    static let bgCream    = background                 // warm cream
    static let bgSky      = secondary.opacity(0.75)    // softer honey
    static let bgBlush    = primary.opacity(0.55)      // dusty peach wash
    static let bgLilac    = primary.opacity(0.32)      // faint peach

    // Tag palette
    static func tag(_ tag: String) -> Color {
        switch tag.lowercased() {
        case "tree", "nature", "fancy", "family": return primary
        case "picnic", "sea", "summer", "fun": return secondary
        case "street food", "good view": return primary.opacity(0.85)
        default: return secondary.opacity(0.9)
        }
    }
}

// MARK: - Gradients

enum AppGradient {
    // Cool screens lead with honey, fade to cream, finish with a touch of peach so
    // they feel like a softer sibling of the warm gradient instead of a separate palette.
    static let background = LinearGradient(
        colors: [AppColor.bgMint, AppColor.bgCream, AppColor.bgLilac],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Warm screens lead with peach, fade to cream, finish with honey — same family,
    // flipped emphasis. Matches the AddAlbumView reference look.
    static let backgroundWarm = LinearGradient(
        colors: [AppColor.bgBlush, AppColor.bgCream, AppColor.bgMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryButton = LinearGradient(
        colors: [
            AppColor.primary,
            AppColor.primary.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let hero = LinearGradient(
        colors: [
            AppColor.primary,
            AppColor.secondary,
            AppColor.primary.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Darker, readable variant of `hero` used as a text/icon fill on cream surfaces.
    /// The bright peach/honey `hero` works fine as a button or avatar background,
    /// but as a text foreground it disappears into the warm background — this stays
    /// in the same roasted/terracotta family while passing AA contrast on cream.
    static let heroText = LinearGradient(
        colors: [
            Color(red: 178 / 255, green:  86 / 255, blue:  56 / 255),  // #B25638 deep terracotta
            Color(red: 200 / 255, green: 110 / 255, blue:  70 / 255),  // #C86E46 burnt amber
            Color(red: 152 / 255, green:  70 / 255, blue:  50 / 255)   // #984632 roast sienna
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glass = LinearGradient(
        colors: [
            Color.white.opacity(0.85),
            Color.white.opacity(0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography (Clash Grotesk)
//
// Add the Clash Grotesk OTF/TTF files to the project and list them in Info.plist
// under "Fonts provided by application" (UIAppFonts). If the font is missing,
// SwiftUI automatically falls back to the system font.
//
// Expected PostScript names:
//   Pally-Regular, Pally-Medium, Pally-Bold   (display, >= 18pt)
//   ClashGrotesk-*                            (body, < 18pt)

extension Font {
    static func clash(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(clashPostScriptName(for: weight, size: size), size: size)
    }

    private static func clashPostScriptName(for weight: Font.Weight, size: CGFloat) -> String {
        if size < 18 {
            switch weight {
            case .ultraLight, .thin:        return "ClashGrotesk-Extralight"
            case .light:                    return "ClashGrotesk-Light"
            case .regular:                  return "ClashGrotesk-Regular"
            case .medium:                   return "ClashGrotesk-Medium"
            case .semibold:                 return "ClashGrotesk-Semibold"
            case .bold, .heavy, .black:     return "ClashGrotesk-Bold"
            default:                        return "ClashGrotesk-Regular"
            }
        } else {
            switch weight {
            case .ultraLight, .thin, .light: return "Pally-Regular"
            case .regular:                   return "Pally-Regular"
            case .medium, .semibold:         return "Pally-Medium"
            case .bold, .heavy, .black:      return "Pally-Bold"
            default:                         return "Pally-Regular"
            }
        }
    }
}

enum AppFont {
    static let displayLarge = Font.clash(44, weight: .bold)
    static let display      = Font.clash(34, weight: .bold)
    static let title        = Font.clash(28, weight: .bold)
    static let titleSmall   = Font.clash(22, weight: .semibold)
    static let headline     = Font.clash(17, weight: .semibold)
    static let body         = Font.clash(16, weight: .regular)
    static let subheadline  = Font.clash(15, weight: .medium)
    static let caption      = Font.clash(13, weight: .medium)
    static let captionBold  = Font.clash(13, weight: .semibold)
    static let tiny         = Font.clash(11, weight: .semibold)
}

// MARK: - Spacing & radii

enum AppSpacing {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let xxxl: CGFloat = 40
}

enum AppRadius {
    static let xs: CGFloat = 8
    static let s:  CGFloat = 12
    static let m:  CGFloat = 16
    static let l:  CGFloat = 20
    static let xl: CGFloat = 28
}

// MARK: - Shadows

enum AppShadow {
    static func soft<V: View>(_ content: V) -> some View {
        content.shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    static func medium<V: View>(_ content: V) -> some View {
        content.shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
    static func strong<V: View>(_ content: V) -> some View {
        content.shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Animation presets

enum AppAnimation {
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.65)
    static let smooth = Animation.spring(response: 0.55, dampingFraction: 0.85)
    static let quick  = Animation.easeOut(duration: 0.18)
}

// MARK: - Haptics

enum Haptics {
    /// Mirrors the Settings toggle (`@AppStorage("pref.hapticFeedback")`).
    /// Defaults to `true` when the user hasn't set the preference yet.
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "pref.hapticFeedback") as? Bool ?? true
    }

    static func tap() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func soft() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }
    static func success() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    static func warning() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
    static func selection() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}

// MARK: - Reusable modifiers

/// Adds a subtle scale-on-press effect to any tappable container.
struct PressableScale: ViewModifier {
    var scale: CGFloat = 0.96
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(AppAnimation.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            Haptics.tap()
                        }
                    }
                    .onEnded { _ in isPressed = false }
            )
    }
}

/// Card-style surface used for content blocks (notes, info cards, etc.).
struct GlassCard: ViewModifier {
    var radius: CGFloat = AppRadius.l
    var padding: CGFloat = AppSpacing.l

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppGradient.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

/// Capsule pill surface (used for inline chips & toolbars).
struct PillSurface: ViewModifier {
    var color: Color = Color.white.opacity(0.85)
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(color, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

/// Input-style rounded surface used by text fields, pickers and compact rows.
struct FieldSurface: ViewModifier {
    var radius: CGFloat = AppRadius.s
    var fill: Color = AppColor.surface.opacity(0.85)

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

/// Small circular glass surface used for icon-only controls.
struct GlassCircleSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppGradient.glass, in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

extension View {
    func pressableScale(_ scale: CGFloat = 0.96) -> some View {
        modifier(PressableScale(scale: scale))
    }
    func glassCard(radius: CGFloat = AppRadius.l, padding: CGFloat = AppSpacing.l) -> some View {
        modifier(GlassCard(radius: radius, padding: padding))
    }
    func pillSurface(color: Color = Color.white.opacity(0.85)) -> some View {
        modifier(PillSurface(color: color))
    }
    func fieldSurface(radius: CGFloat = AppRadius.s, fill: Color = AppColor.surface.opacity(0.85)) -> some View {
        modifier(FieldSurface(radius: radius, fill: fill))
    }
    func glassCircleSurface() -> some View {
        modifier(GlassCircleSurface())
    }

    /// Springy entrance — applied when content first appears.
    func bounceOnAppear(delay: Double = 0) -> some View {
        modifier(BounceOnAppear(delay: delay))
    }
}

struct BounceOnAppear: ViewModifier {
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : 0.92)
            .offset(y: shown ? 0 : 12)
            .onAppear {
                withAnimation(AppAnimation.bouncy.delay(delay)) {
                    shown = true
                }
            }
    }
}

// MARK: - Shimmer placeholder

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5)
                    .offset(x: phase * geo.size.width)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmering() -> some View { modifier(Shimmer()) }
}
