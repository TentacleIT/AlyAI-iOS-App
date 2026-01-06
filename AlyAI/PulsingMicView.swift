import SwiftUI

struct PulsingMicView: View {
    @State private var waveScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.accentPrimary.opacity(0.5), lineWidth: 2)
                    .scaleEffect(waveScale)
                    .opacity(2 - waveScale)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.5),
                        value: waveScale
                    )
            }
        }
        .onAppear {
            waveScale = 2.0
        }
    }
}
