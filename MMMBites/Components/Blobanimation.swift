
import SwiftUI

public struct AnimatedBlobBackground: View {
    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base gradient: soft peach top-left → warm cream centre → blush bottom-right
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 255/255, green:201/255, blue: 208/255), location: 0.0),
                        .init(color: Color(red: 255/255, green: 232/255, blue: 230/255), location: 0.5),
                        .init(color: Color(red: 255/255, green: 201/255, blue: 208/255), location: 1.0),
                    ],
                    //255, 232, 230
                    //255, 201, 208
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // F7E0DE — lightest blush, top left
                Blob(color: Color(red: 248/255, green: 200/255, blue: 196/255),
                     size: 280, anchorX: geo.size.width * 0.05, anchorY: geo.size.height * 0.08,
                     duration: 6.5, driftX: 65, driftY: 70)

                // F8C8C4 — soft rose, top right
                Blob(color: Color(red: 250/255, green: 230/255, blue: 204/255),
                     size: 260, anchorX: geo.size.width * 0.95, anchorY: geo.size.height * 0.22,
                     duration: 7.5, driftX: -55, driftY: 80)

                //248, 200, 196
                // E9B8A0 — warm terracotta, bottom left
                Blob(color: Color(red: 247/255, green: 213/255, blue: 191/255),
                     size: 270, anchorX: geo.size.width * 0.05, anchorY: geo.size.height * 0.88,
                     duration: 6.0, driftX: 60, driftY: -65)

                // E7AA8D — deeper peach, bottom right
                Blob(color: Color(red: 248/255, green: 200/255, blue: 196/255),
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

