//
//  AppBackground.swift
//  MMMBites
//
//  Reusable animated background used across the app for a consistent feel.
//

import SwiftUI
import SpriteKit

struct AppBackground: View {
    /// Variant usage:
    /// - `.cool` is the default for content browsing, detail pages, and settings.
    /// - `.warm` is for creation/editing flows, authentication, onboarding, and modal sheets.
    enum Variant {
        case cool
        case warm
    }

    var variant: Variant = .cool
    var animated: Bool = true

    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gradient
                    .ignoresSafeArea()

                particleLayer(size: geometry.size)

                blob(color: blobColors.0, size: 320)
                    .offset(x: animate ? -120 : -150, y: animate ? -260 : -220)
                blob(color: blobColors.1, size: 280)
                    .offset(x: animate ? 150 : 130, y: animate ? -90 : -60)
                blob(color: blobColors.2, size: 360)
                    .offset(x: animate ? -90 : -60, y: animate ? 260 : 300)
                blob(color: blobColors.3, size: 240)
                    .offset(x: animate ? 160 : 140, y: animate ? 320 : 360)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }

    private var gradient: some View {
        Group {
            switch variant {
            case .cool:
                AppGradient.background
            case .warm:
                AppGradient.backgroundWarm
            }
        }
    }

    private var blobColors: (Color, Color, Color, Color) {
        switch variant {
        case .cool:
            // Pre-GPT pastel set — sky/mint/cream/lilac for a fresh stage
            // that lets warm food photos lead.
            return (
                Color(red: 0.80, green: 0.91, blue: 0.99).opacity(0.55),  // sky
                Color(red: 0.81, green: 0.93, blue: 0.91).opacity(0.55),  // mint
                Color(red: 0.98, green: 0.94, blue: 0.80).opacity(0.55),  // lemon cream
                Color(red: 0.90, green: 0.86, blue: 0.99).opacity(0.45)   // lilac
            )
        case .warm:
            // Rose-led, finished with peach — same family, warmer emphasis.
            return (
                AppColor.bgRose.opacity(0.60),
                AppColor.bgPeach.opacity(0.55),
                AppColor.bgCream.opacity(0.55),
                AppColor.bgBlush.opacity(0.45)
            )
        }
    }

    private var particleColors: (SKColor, SKColor) {
        switch variant {
        case .cool:
            // Sky blue + lemon cream — pre-GPT pastel mix.
            return (
                SKColor(red: 195 / 255, green: 236 / 255, blue: 255 / 255, alpha: 1.0),
                SKColor(red: 247 / 255, green: 235 / 255, blue: 204 / 255, alpha: 1.0)
            )
        case .warm:
            // Rose + peach dusting.
            return (
                SKColor(red: 248 / 255, green: 200 / 255, blue: 196 / 255, alpha: 1.0),
                SKColor(red: 247 / 255, green: 213 / 255, blue: 191 / 255, alpha: 1.0)
            )
        }
    }

    private func particleLayer(size: CGSize) -> some View {
        SpriteView(
            scene: makeParticleScene(size: size),
            options: [.allowsTransparency]
        )
        .frame(width: size.width + 500, height: size.height + 500)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .opacity(animated ? 0.85 : 0.45)
    }

    private func blob(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 80)
            .allowsHitTesting(false)
    }

    private func makeParticleScene(size: CGSize) -> SKScene {
        let expandedSize = CGSize(width: size.width + 500, height: size.height + 500)
        let scene = SKScene(size: expandedSize)
        scene.backgroundColor = .clear
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        addParticle(
            named: "MyParticle",
            to: scene,
            size: expandedSize,
            baseColor: particleColors.0,
            zPosition: 1
        )

        addParticle(
            named: "MyParticle2",
            to: scene,
            size: expandedSize,
            baseColor: particleColors.1,
            zPosition: 2
        )

        return scene
    }

    private func addParticle(
        named fileName: String,
        to scene: SKScene,
        size: CGSize,
        baseColor: SKColor,
        zPosition: CGFloat
    ) {
        guard let emitter = SKEmitterNode(fileNamed: fileName) else {
            print("Could not find \(fileName).sks")
            return
        }

        emitter.position = CGPoint(x: 0, y: 0)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        emitter.particleColor = baseColor
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorRedRange = 0.5
        emitter.particleColorGreenRange = 0.5
        emitter.particleColorBlueRange = 0.5
        emitter.particleColorAlphaRange = 0.2
        emitter.zPosition = zPosition
        scene.addChild(emitter)
    }
}

#Preview {
    AppBackground()
}
