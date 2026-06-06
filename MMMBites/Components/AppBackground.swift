//
//  AppBackground.swift
//  MMMBites
//
//  Reusable animated background used across the app for a consistent feel.
//  A slow-breathing gradient with soft floating blobs.
//

import SwiftUI

struct AppBackground: View {
    enum Variant {
        case cool   // mint / cream / sky  (default)
        case warm   // blush / cream / lilac
    }

    var variant: Variant = .cool
    var animated: Bool = true

    @State private var animate = false

    var body: some View {
        ZStack {
            gradient
                .ignoresSafeArea()

            // Soft floating colour blobs for depth.
            blob(color: blobColors.0, size: 320)
                .offset(x: animate ? -120 : -150, y: animate ? -260 : -220)
            blob(color: blobColors.1, size: 280)
                .offset(x: animate ? 150 : 130, y: animate ? -90 : -60)
            blob(color: blobColors.2, size: 360)
                .offset(x: animate ? -90 : -60, y: animate ? 260 : 300)
            blob(color: blobColors.3, size: 240)
                .offset(x: animate ? 160 : 140, y: animate ? 320 : 360)
        }
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
            case .cool: AppGradient.background
            case .warm: AppGradient.backgroundWarm
            }
        }
    }

    private var blobColors: (Color, Color, Color, Color) {
        switch variant {
        case .cool:
            return (
                AppColor.bgSky.opacity(0.55),
                AppColor.bgMint.opacity(0.55),
                AppColor.bgCream.opacity(0.55),
                AppColor.bgLilac.opacity(0.45)
            )
        case .warm:
            return (
                AppColor.bgBlush.opacity(0.6),
                AppColor.bgLilac.opacity(0.55),
                AppColor.bgCream.opacity(0.55),
                AppColor.bgSky.opacity(0.40)
            )
        }
    }

    private func blob(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 80)
            .allowsHitTesting(false)
    }
}

#Preview {
    AppBackground()
}
