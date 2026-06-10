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
    // Brand palette — warm berry and coral tones that sit naturally on the
    // blush/peach backgrounds while keeping controls readable.
    static let primary    = Color(red: 166 / 255, green:  54 / 255, blue:  91 / 255)   // #A6365B berry rose
    static let secondary  = Color(red: 226 / 255, green: 111 / 255, blue:  82 / 255)   // #E26F52 coral
    static let accent     = Color(red: 230 / 255, green: 164 / 255, blue:  63 / 255)   // #E6A43F warm honey
    static let background = Color.white

    // Surfaces
    static let surface    = Color.white
    static let surfaceMuted = Color.white.opacity(0.55)
    static let surfaceGlass = Color.white.opacity(0.7)

    // Ink (text)
    static let ink        = Color(red: 0.10, green: 0.10, blue: 0.14)                  // #191923
    static let inkMuted   = Color(red: 0.34, green: 0.36, blue: 0.42)                  // #575C6B
    static let inkFaint   = Color(red: 0.56, green: 0.58, blue: 0.63)                  // #8F94A1

    // Pastel background stops — Ada pink family used by the warm variant and
    // shimmer placeholders. Cool variant inlines its own pastels in AppGradient.
    static let bgBlush    = Color(red: 255 / 255, green: 201 / 255, blue: 208 / 255)   // #FFC9D0
    static let bgCream    = Color(red: 255 / 255, green: 232 / 255, blue: 230 / 255)   // #FFE8E6
    static let bgPeach    = Color(red: 247 / 255, green: 213 / 255, blue: 191 / 255)   // #F7D5BF
    static let bgRose     = Color(red: 248 / 255, green: 200 / 255, blue: 196 / 255)   // #F8C8C4
    static let bgWarm     = Color(red: 250 / 255, green: 230 / 255, blue: 204 / 255)   // #FAE6CC

    // Legacy aliases (kept so shimmer placeholders compile)
    static let bgMint     = bgWarm
    static let bgSky      = bgBlush
    static let bgLilac    = bgPeach

    // Tag palette — bright multi-color pastels. Each category gets its own
    // hue so chips pop on the mint background without all reading as one tone.
    static func tag(_ tag: String) -> Color {
        switch tag.lowercased() {
        case "tree", "nature":    return Color(red: 0.40, green: 0.74, blue: 0.51)   // #66BC82 fresh green
        case "picnic":            return Color(red: 0.96, green: 0.62, blue: 0.30)   // #F59E4D warm orange
        case "fancy":             return Color(red: 0.98, green: 0.78, blue: 0.34)   // #FAC757 honey yellow
        case "family":            return Color(red: 0.95, green: 0.55, blue: 0.70)   // #F28BB3 soft pink
        case "sea", "summer":     return Color(red: 0.34, green: 0.71, blue: 0.92)   // #56B5EB sky blue
        case "fun":               return Color(red: 0.94, green: 0.47, blue: 0.60)   // #F0789A hot pink
        case "street food":       return Color(red: 0.70, green: 0.45, blue: 0.95)   // #B273F2 purple
        case "good view":         return Color(red: 0.36, green: 0.65, blue: 0.96)   // #5CA6F5 cornflower
        default:                  return Color(red: 0.62, green: 0.62, blue: 0.72)   // #9E9EB8 neutral gray
        }
    }
}

// MARK: - Gradients

enum AppGradient {
    // Cool screens — fresh pastel (mint → lemon cream → sky). Used on album
    // browsing surfaces so warm food photos pop against a neutral cool stage.
    static let background = LinearGradient(
        colors: [
            Color(red: 0.81, green: 0.93, blue: 0.91),   // #CEEDE7 mint
            Color(red: 0.98, green: 0.94, blue: 0.80),   // #FAF0CC lemon cream
            Color(red: 0.80, green: 0.91, blue: 0.99)    // #CCE8FD sky
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Warm screens — rose-led, ending in peach. Used on create/edit sheets
    // and personal surfaces (profile, recap) for an intimate warm tone.
    static let backgroundWarm = LinearGradient(
        colors: [AppColor.bgRose, AppColor.bgCream, AppColor.bgPeach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Berry fade for primary actions. The darker stop keeps white labels
    // readable without the harsh neon feel of the previous palette.
    static let primaryButton = LinearGradient(
        colors: [
            Color(red: 188 / 255, green:  62 / 255, blue: 101 / 255),  // #BC3E65
            Color(red: 126 / 255, green:  38 / 255, blue:  69 / 255)   // #7E2645
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Warm profile/hero sweep using berry, coral, and honey.
    static let hero = LinearGradient(
        colors: [
            AppColor.secondary,
            AppColor.primary,
            Color(red: 126 / 255, green:  38 / 255, blue:  69 / 255)   // #7E2645 deep berry
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dark readable variant for text/icon fills where contrast matters on
    /// pastel surfaces.
    static let heroText = LinearGradient(
        colors: [
            Color(red: 126 / 255, green:  38 / 255, blue:  69 / 255),  // #7E2645
            Color(red: 104 / 255, green:  31 / 255, blue:  57 / 255),  // #681F39
            Color(red:  82 / 255, green:  24 / 255, blue:  45 / 255)   // #52182D
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
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func soft() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}

// MARK: - Reusable views

/// Trailing X button that clears a text binding when the field is not empty.
struct FieldClearButton: View {
    @Binding var text: String

    var body: some View {
        Group {
            if !text.isEmpty {
                Button {
                    text = ""
                    Haptics.tap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(AppColor.inkFaint.opacity(0.7))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .animation(AppAnimation.snappy, value: text.isEmpty)
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
