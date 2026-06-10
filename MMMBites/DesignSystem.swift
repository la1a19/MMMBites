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
    // Primary brand
    static let primary    = Color(red: 0.96, green: 0.49, blue: 0.42)   // warm coral
    static let secondary  = Color(red: 0.55, green: 0.45, blue: 0.92)   // soft lavender
    static let accent     = Color(red: 0.99, green: 0.78, blue: 0.36)   // golden honey

    // Surfaces
    static let surface    = Color.white
    static let surfaceMuted = Color.white.opacity(0.55)
    static let surfaceGlass = Color.white.opacity(0.7)

    // Ink (text)
    static let ink        = Color(red: 0.10, green: 0.10, blue: 0.14)
    static let inkMuted   = Color(red: 0.34, green: 0.36, blue: 0.42)
    static let inkFaint   = Color(red: 0.56, green: 0.58, blue: 0.63)

    // Pastel background stops
    static let bgMint     = Color(red: 0.81, green: 0.93, blue: 0.91)
    static let bgCream    = Color(red: 0.98, green: 0.94, blue: 0.80)
    static let bgSky      = Color(red: 0.80, green: 0.91, blue: 0.99)
    static let bgBlush    = Color(red: 0.99, green: 0.86, blue: 0.88)
    static let bgLilac    = Color(red: 0.90, green: 0.86, blue: 0.99)

    // Tag palette
    static func tag(_ tag: String) -> Color {
        switch tag.lowercased() {
        case "tree", "nature":    return Color(red: 0.40, green: 0.74, blue: 0.51)
        case "picnic":            return Color(red: 0.96, green: 0.62, blue: 0.30)
        case "fancy":             return Color(red: 0.98, green: 0.78, blue: 0.34)
        case "family":            return Color(red: 0.95, green: 0.55, blue: 0.70)
        case "sea", "summer":     return Color(red: 0.34, green: 0.71, blue: 0.92)
        case "fun":               return Color(red: 0.94, green: 0.47, blue: 0.60)
        case "street food":       return Color(red: 0.70, green: 0.45, blue: 0.95)
        case "good view":         return Color(red: 0.36, green: 0.65, blue: 0.96)
        default:                  return Color(red: 0.62, green: 0.62, blue: 0.72)
        }
    }
}

// MARK: - Gradients

enum AppGradient {
    static let background = LinearGradient(
        colors: [AppColor.bgMint, AppColor.bgCream, AppColor.bgSky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundWarm = LinearGradient(
        colors: [AppColor.bgBlush, AppColor.bgCream, AppColor.bgLilac],
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
            Color(red: 1.00, green: 0.42, blue: 0.36),   // tomato
            Color(red: 0.88, green: 0.23, blue: 0.43),   // raspberry
            Color(red: 0.55, green: 0.12, blue: 0.29)    // dark cherry
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
