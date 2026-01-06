import SwiftUI

// MARK: - Premium Button Style

struct PremiumButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .alyFont(.alyButton)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Primary Gradient Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primaryRadiant)
                        .shadow(
                            color: Color.accentPrimary.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    // Subtle Sheen Overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                    
                    // Light Stroke for Contrast
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                }
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(
                .spring(response: 0.35, dampingFraction: 0.8),
                value: configuration.isPressed
            )
    }
}

// MARK: - Destructive Button Style (End Call)

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .alyFont(.alyButton)
            .padding()
            .background(
                ZStack {
                    // Base Error Color
                    Circle()
                        .fill(Color.error)
                        .shadow(
                            color: Color.error.opacity(0.5),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    
                    // Gradient Sheen for Urgency
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(
                .spring(response: 0.35, dampingFraction: 0.8),
                value: configuration.isPressed
            )
    }
}

// MARK: - Apple-Style Primary Button (High Contrast)

struct AlyPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold)) // Apple Standard
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // 1. Shadow / Elevation
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.black.opacity(0.2))
                            .shadow(
                                color: Color.black.opacity(0.25),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                    }
                    
                    // 2. Main Body Gradient (Deep Black vs Pure White)
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            colorScheme == .dark
                            ? AnyShapeStyle(Color.white)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(white: 0.15), // Subtle highlight top
                                        Color.black         // Deep black body
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                    
                    // 3. Top Sheen / Reflection (Apple Style)
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .dark ? 0.8 : 0.25),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .padding(1) // Inset slightly
                }
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
