import SwiftUI

// MARK: - App Theme

enum AppTheme {

    // MARK: Core Palette

    /// Primary brand color — neon green (#00FF41) in dark, very dark green in light for button contrast.
    static let primary = Color(
        light: Color(hex: 0x034D22),
        dark: Color(hex: 0x00FF41)
    )

    /// Secondary — dark navy in light, cool cyan in dark.
    static let secondary = Color(
        light: Color(hex: 0x002E47),
        dark: Color(hex: 0x00D4FF)
    )

    /// Accent — dark green in light, bright mint in dark.
    static let accent = Color(
        light: Color(hex: 0x04501F),
        dark: Color(hex: 0x39FF85)
    )

    /// Warning — consistent orange.
    static let warning = Color(
        light: Color(hex: 0xE8780A),
        dark: Color(hex: 0xFF9F0A)
    )

    /// Danger — consistent red.
    static let danger = Color(
        light: Color(hex: 0xD32F2F),
        dark: Color(hex: 0xFF453A)
    )

    // MARK: Surfaces

    /// Card background tint.
    static let cardTint = Color(
        light: Color(hex: 0xF0F4F8),
        dark: Color(hex: 0x0A1A12)
    )

    /// Subtle text — secondary labels.
    static let subtleText = Color(
        light: Color(hex: 0x6B7280),
        dark: Color(hex: 0x8B9A8F)
    )

    // MARK: Gradients

    static let gradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Color Extensions

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }

    /// Creates an adaptive color that resolves based on the current color scheme.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
