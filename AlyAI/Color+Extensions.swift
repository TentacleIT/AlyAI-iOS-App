#if !os(watchOS)

import SwiftUI

// MARK: - View + Vibrancy

extension View {
    
    /// Applies a vibrant, glowing effect to the view, suitable for dark mode.
    /// This effect uses a combination of blur, saturation, and color overlays to create a sense of depth and radiance.
    ///
    /// - Parameters:
    ///   - color: The color of the glow.
    ///   - blur: The radius of the blur effect.
    /// - Returns: A view with the vibrant glow effect.
    func vibrantGlow(color: Color, blur: CGFloat = 20) -> some View {
        ZStack {
            self

            // 1. Inner Glow (Brighter)
            self
                .blur(radius: blur / 2)
                .saturation(1.5)
                .blendMode(.multiply)
                .allowsHitTesting(false)

            // 2. Outer Glow (Softer)
            self
                .blur(radius: blur)
                .saturation(2)
                .blendMode(.overlay)
                .allowsHitTesting(false)

            // 3. Color Overlay (Tint)
            self
                .blur(radius: blur)
                .foregroundColor(color)
                .blendMode(.overlay)
                .saturation(2)
                .allowsHitTesting(false)
        }
    }
}

#endif
