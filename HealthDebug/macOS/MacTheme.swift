import SwiftUI
import AppKit

// MARK: - App Theme (macOS — mirrors iOS Theme.swift without UIKit)

enum AppTheme {

    static let primary = Color(
        light: Color(hex: 0x0A7E5A),
        dark: Color(hex: 0x30D158)
    )

    static let secondary = Color(
        light: Color(hex: 0x002E47),
        dark: Color(hex: 0x00D4FF)
    )

    static let accent = Color(
        light: Color(hex: 0x0D6E4E),
        dark: Color(hex: 0x34C759)
    )

    static let warning = Color(
        light: Color(hex: 0xE8780A),
        dark: Color(hex: 0xFF9F0A)
    )

    static let danger = Color(
        light: Color(hex: 0xD32F2F),
        dark: Color(hex: 0xFF453A)
    )

    static let cardTint = Color(
        light: Color(hex: 0xF0F4F8),
        dark: Color(hex: 0x0A1A12)
    )

    static let subtleText = Color(
        light: Color(hex: 0x6B7280),
        dark: Color(hex: 0x8B9A8F)
    )

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

// MARK: - Color Extensions (macOS — uses NSColor instead of UIColor)

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

    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.name == .darkAqua || appearance.name == .vibrantDark
                || appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
    }
}
