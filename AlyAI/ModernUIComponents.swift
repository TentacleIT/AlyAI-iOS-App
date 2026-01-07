import SwiftUI

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .alyCard
    var borderColor: Color = .clear
    var shadowColor: Color = Color.black.opacity(0.1)
    var shadowRadius: CGFloat = 8
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    
    init(backgroundColor: Color = .alyCard, borderColor: Color = .clear, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Modern Button Styles
struct ModernPrimaryButton: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.alyaiPrimary,
                        Color.alyaiPrimary.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernSecondaryButton: ButtonStyle {
    var color: Color = .alyaiPrimary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernTertiaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(.alyaiPrimary)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modern Input Field
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    var backgroundColor: Color = .alyCard
    var foregroundColor: Color = .alyTextPrimary
    var accentColor: Color = .alyaiPrimary
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .frame(width: 24)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(foregroundColor)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(foregroundColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Modern Segmented Control
struct ModernSegmentedControl: View {
    @Binding var selectedIndex: Int
    let options: [String]
    var accentColor: Color = .alyaiPrimary
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: { selectedIndex = index }) {
                    Text(option)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(
                            selectedIndex == index ? .white : .alyTextSecondary
                        )
                        .background(
                            selectedIndex == index
                            ? accentColor
                            : Color.clear
                        )
                }
            }
        }
        .background(Color.alyCard)
        .cornerRadius(10)
        .padding(4)
        .background(Color.alyCard.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Modern Progress Bar
struct ModernProgressBar: View {
    let progress: Double
    let height: CGFloat = 8
    var backgroundColor: Color = .alyCard
    var foregroundColor: Color = .alyaiPrimary
    var showLabel: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    foregroundColor,
                                    foregroundColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: height)
            
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.alyTextSecondary)
            }
        }
    }
}

// MARK: - Modern Toggle
struct ModernToggle: View {
    @Binding var isOn: Bool
    let label: String
    var accentColor: Color = .alyaiPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.alyTextPrimary)
            
            Spacer()
            
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isOn ? accentColor : Color.alyCard)
                
                Circle()
                    .fill(Color.white)
                    .padding(2)
            }
            .frame(width: 52, height: 32)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }
        }
        .padding()
        .background(Color.alyCard)
        .cornerRadius(12)
    }
}

// MARK: - Modern Alert Card
struct ModernAlertCard: View {
    let type: AlertType
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String = "Dismiss"
    
    enum AlertType {
        case success
        case warning
        case error
        case info
        
        var backgroundColor: Color {
            switch self {
            case .success: return Color.green.opacity(0.1)
            case .warning: return Color.orange.opacity(0.1)
            case .error: return Color.red.opacity(0.1)
            case .info: return Color.blue.opacity(0.1)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.borderColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.alyTextPrimary)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.alyTextSecondary)
                }
                
                Spacer()
            }
            
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(type.borderColor)
                }
            }
        }
        .padding()
        .background(type.backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.borderColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Loading Indicator
struct ModernLoadingIndicator: View {
    @State private var isAnimating = false
    var size: CGFloat = 50
    var color: Color = .alyaiPrimary
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Modern Empty State
struct ModernEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.alyaiPrimary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.alyTextPrimary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.alyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                }
                .buttonStyle(ModernPrimaryButton())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.alyCard)
        .cornerRadius(16)
    }
}

// MARK: - Modern Gradient Background
struct ModernGradientBackground: View {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ModernCard {
            Text("Modern Card")
                .font(.headline)
        }
        
        Button("Primary Button") {}
            .buttonStyle(ModernPrimaryButton())
        
        Button("Secondary Button") {}
            .buttonStyle(ModernSecondaryButton())
        
        ModernTextField(text: .constant(""), placeholder: "Enter text", icon: "envelope", isSecure: false)
        
        ModernProgressBar(progress: 0.65, showLabel: true)
        
        ModernLoadingIndicator()
    }
    .padding()
    .background(Color.alyBackground)
}
