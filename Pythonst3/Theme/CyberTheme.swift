import SwiftUI

enum CyberTheme {
    static let background = Color(red: 0.016, green: 0.024, blue: 0.031)
    static let surface = Color(red: 0.043, green: 0.063, blue: 0.078)
    static let surfaceElevated = Color(red: 0.067, green: 0.094, blue: 0.114)

    static let neonGreen = Color(red: 0.204, green: 1.000, blue: 0.549)
    static let neonCyan = Color(red: 0.235, green: 0.902, blue: 1.000)
    static let neonMagenta = Color(red: 1.000, green: 0.267, blue: 0.839)
    static let amber = Color(red: 1.000, green: 0.749, blue: 0.267)
    static let danger = Color(red: 1.000, green: 0.294, blue: 0.384)

    static let textPrimary = Color(red: 0.906, green: 0.945, blue: 0.957)
    static let textSecondary = Color(red: 0.502, green: 0.588, blue: 0.627)
    static let textMuted = Color(red: 0.337, green: 0.404, blue: 0.439)

    static let codeKeyword = Color(red: 1.000, green: 0.431, blue: 0.706)
    static let codeString = Color(red: 0.639, green: 0.949, blue: 0.541)
    static let codeComment = Color(red: 0.412, green: 0.502, blue: 0.541)
    static let codeNumber = Color(red: 1.000, green: 0.788, blue: 0.404)
    static let codeFunction = Color(red: 0.463, green: 0.847, blue: 1.000)

    static func arabic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

struct GridPattern: Shape {
    var spacing: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }
        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        return path
    }
}

struct CyberBackground: View {
    var body: some View {
        ZStack {
            CyberTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ZStack {
                    RadialGradient(
                        colors: [CyberTheme.neonGreen.opacity(0.10), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: max(proxy.size.width, proxy.size.height) * 0.95
                    )
                    RadialGradient(
                        colors: [CyberTheme.neonCyan.opacity(0.07), .clear],
                        center: .bottomLeading,
                        startRadius: 0,
                        endRadius: max(proxy.size.width, proxy.size.height) * 1.05
                    )
                    GridPattern()
                        .stroke(CyberTheme.neonCyan.opacity(0.045), lineWidth: 0.5)
                }
            }
            .ignoresSafeArea()
        }
    }
}

struct NeonPanel: ViewModifier {
    var accent: Color = CyberTheme.neonGreen
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(CyberTheme.surface.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.55), accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: accent.opacity(0.10), radius: 18, x: 0, y: 0)
    }
}

extension View {
    func neonPanel(accent: Color = CyberTheme.neonGreen, cornerRadius: CGFloat = 16) -> some View {
        modifier(NeonPanel(accent: accent, cornerRadius: cornerRadius))
    }
}

struct CyberButtonStyle: ButtonStyle {
    var tint: Color = CyberTheme.neonGreen
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CyberTheme.arabic(14, weight: .semibold))
            .foregroundStyle(filled ? CyberTheme.background : tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(filled ? tint : tint.opacity(configuration.isPressed ? 0.22 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tint.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(CyberTheme.mono(10, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.10)))
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.8))
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(CyberTheme.mono(10, weight: .semibold))
            .tracking(2)
            .foregroundStyle(CyberTheme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
