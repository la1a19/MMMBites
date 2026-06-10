import SwiftUI

public struct AnimatedBlobBackground: View {
    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: AppColor.background, location: 0.0),
                        .init(color: AppColor.secondary, location: 0.5),
                        .init(color: AppColor.primary.opacity(0.65), location: 1.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Blob(color: AppColor.primary,
                     size: 280, anchorX: geo.size.width * 0.05, anchorY: geo.size.height * 0.08,
                     duration: 6.5, driftX: 65, driftY: 70)

                Blob(color: AppColor.secondary,
                     size: 260, anchorX: geo.size.width * 0.95, anchorY: geo.size.height * 0.22,
                     duration: 7.5, driftX: -55, driftY: 80)

                Blob(color: AppColor.primary.opacity(0.75),
                     size: 270, anchorX: geo.size.width * 0.05, anchorY: geo.size.height * 0.88,
                     duration: 6.0, driftX: 60, driftY: -65)

                Blob(color: AppColor.background,
                     size: 250, anchorX: geo.size.width * 0.95, anchorY: geo.size.height * 0.78,
                     duration: 7.0, driftX: -50, driftY: -55)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private struct Blob: View {
    let color: Color
    let size: CGFloat
    let anchorX: CGFloat
    let anchorY: CGFloat
    let duration: Double
    let driftX: CGFloat
    let driftY: CGFloat

    @State private var phase: Bool = false

    var body: some View {
        Circle()
            .fill(color.opacity(0.80))
            .frame(width: size, height: size)
            .blur(radius: 18)
            .offset(
                x: phase ? driftX : -driftX,
                y: phase ? driftY : -driftY
            )
            .position(x: anchorX, y: anchorY)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    phase = true
                }
            }
    }
}

#Preview {
    AnimatedBlobBackground()
}
