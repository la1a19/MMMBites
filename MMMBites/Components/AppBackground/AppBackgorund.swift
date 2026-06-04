//
//  Backgorundmaster.swift
//  MMMBites
//
//  Created by Yat Tin lee on 4/6/2026.
//

// AppBackground.swift
import SwiftUI
import SpriteKit

struct AppBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 211/255, green: 245/255, blue: 244/255), // D3F5F4
                        Color(red: 247/255, green: 235/255, blue: 204/255), // F7EBCC
                        Color(red: 195/255, green: 236/255, blue: 255/255)  // C3ECFF
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                SpriteView(
                    scene: makeParticleScene(size: geometry.size),
                    options: [.allowsTransparency]
                )
                .frame(
                    width: geometry.size.width + 500,
                    height: geometry.size.height + 500
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .opacity(0.85)
            }
        }
        .ignoresSafeArea()
    }

    private func makeParticleScene(size: CGSize) -> SKScene {
        let expandedSize = CGSize(
            width: size.width + 500,
            height: size.height + 500
        )

        let scene = SKScene(size: expandedSize)
        scene.backgroundColor = .clear
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        addParticle(
            named: "MyParticle",
            to: scene,
            size: expandedSize,
            baseColor: SKColor(red: 195/255, green: 236/255, blue: 255/255, alpha: 1.0),
            zPosition: 1
        )

        addParticle(
            named: "MyParticle2",
            to: scene,
            size: expandedSize,
            baseColor: SKColor.yellow,
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
        if let emitter = SKEmitterNode(fileNamed: fileName) {
            emitter.position = CGPoint(x: 0, y: 0)

            emitter.particlePositionRange = CGVector(
                dx: size.width,
                dy: size.height
            )

            emitter.particleColor = baseColor
            emitter.particleColorBlendFactor = 1.0

            // Random colour variation
            emitter.particleColorRedRange = 0.5
            emitter.particleColorGreenRange = 0.5
            emitter.particleColorBlueRange = 0.5
            emitter.particleColorAlphaRange = 0.2

            emitter.zPosition = zPosition
            scene.addChild(emitter)
        } else {
            print("Could not find \(fileName).sks")
        }
    }
}

#Preview {
    AppBackground()
        
}
