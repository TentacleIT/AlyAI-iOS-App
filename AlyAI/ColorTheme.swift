import SwiftUI
import UIKit

// MARK: - Color Initializers

extension Color {

    /// Create Color from HEX string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Dynamic Light / Dark Color
    init(light: String, dark: String) {
        self = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - AlyAI Color Theme

extension Color {

    // MARK: - Semantic Colors

    static let backgroundPrimary = Color(light: "#FFFFFF", dark: "#111827")
    static let surfacePrimary = Color(light: "#F9FAFB", dark: "#1F2937")
    static let textPrimary = Color(light: "#1F2937", dark: "#F9FAFB")
    static let textSecondary = Color(light: "#6B7280", dark: "#9CA3AF")
    static let borderSubtle = Color(light: "#E5E7EB", dark: "#374151")
    static let accentPrimary = Color(light: "#4F46E5", dark: "#6366F1")

    static let error = Color(light: "#EF4444", dark: "#F87171")
    static let warning = Color(light: "#F59E0B", dark: "#FBBF24")
    static let success = Color(light: "#10B981", dark: "#34D399")
    static let shadow = Color(light: "#000000", dark: "#000000").opacity(0.1)

    // MARK: - Legacy Aliases

    static let alyBackground = backgroundPrimary
    static let alyCard = surfacePrimary
    static let alyPrimary = accentPrimary
    static let alyTextPrimary = textPrimary
    static let alyTextSecondary = textSecondary
    static let alyDanger = error

    static let alySecondary = Color(light: "#4FD1C5", dark: "#A7F3D0")
    static let alyAmber = Color(light: "#F6AD55", dark: "#FBBF24")
    static let alyTextDisabled = Color(light: "#9CA3AF", dark: "#6B7280")

    static let alyaiPrimary = alyPrimary
    static let alyaiEmotional = alyAmber
    static let alyaiMental = alyPrimary
    static let alyaiPhysical = alySecondary

    static let alyaiLightPurple = surfacePrimary
    static let alyaiLightBlue = surfacePrimary
    static let alyaiLightGreen = surfacePrimary

    // MARK: - Gradients

    static let alyaiGradient = LinearGradient(
        colors: [alyPrimary, alySecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let alyaiMentalGradient = LinearGradient(
        colors: [alyPrimary, surfacePrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let alyaiPhysicalGradient = LinearGradient(
        colors: [alySecondary, surfacePrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Radiance Enhancements

    static let primaryRadiant = LinearGradient(
        colors: [accentPrimary, accentPrimary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryRadiant = LinearGradient(
        colors: [alySecondary, alySecondary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let emotionalRadiant = LinearGradient(
        colors: [alyAmber, alyAmber.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardSheen = LinearGradient(
        colors: [Color.white.opacity(0.2), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
