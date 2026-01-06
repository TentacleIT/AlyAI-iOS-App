import SwiftUI

// MARK: - AlyAI Font System

extension Font {
    
    // MARK: - Dynamic Type Styles
    
    /// Headline style, equivalent to `.headline` but with semibold weight.
    static var alyHeadline: Font { .system(.headline, design: .default).weight(.semibold) }
    
    /// Section title style, medium weight.
    static var alySectionTitle: Font { .system(.subheadline, design: .default).weight(.medium) }
    
    /// Body text, regular weight.
    static var alyBody: Font { .system(.body, design: .default).weight(.regular) }
    
    /// Caption text, regular weight, slightly smaller.
    static var alyCaption: Font { .system(.caption, design: .default).weight(.regular) }
    
    /// Button label style, semibold weight with slight letter spacing.
    static var alyButton: Font { .system(.callout, design: .default).weight(.semibold) }
}

// MARK: - View Modifier for Typography

extension View {
    /// Applies a specific AlyAI font style and adds tracking.
    func alyFont(_ style: Font, tracking: CGFloat = 0.1) -> some View {
        self
            .font(style)
            .tracking(tracking)
    }
}
