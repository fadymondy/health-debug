import SwiftUI
import UIKit

// MARK: - IBM Plex Sans Font System

extension Font {
    /// Returns the IBM Plex Sans (Arabic or Latin) family name based on current locale.
    static var ibmFamily: String {
        let isArabic = Bundle.main.preferredLocalizations.first?.hasPrefix("ar") == true
        return isArabic ? "IBM Plex Sans Arabic" : "IBMPlexSans"
    }

    /// Dynamic-Type–aware IBM Plex Sans font for a given text style.
    static func ibm(_ style: Font.TextStyle) -> Font {
        .custom(ibmFamily, size: defaultSize(for: style), relativeTo: style)
    }

    /// Fixed-size IBM Plex Sans font.
    static func ibm(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(ibmFamily, fixedSize: size).weight(weight)
    }

    private static func defaultSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle:  return 34
        case .title:       return 28
        case .title2:      return 22
        case .title3:      return 20
        case .headline:    return 17
        case .body:        return 17
        case .callout:     return 16
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption:     return 12
        case .caption2:    return 11
        @unknown default:  return 17
        }
    }
}

// MARK: - Global UIKit font override

enum IBMPlexFontSetup {
    /// Call once at app launch to set IBM Plex Sans as the default font for UIKit
    /// components (navigation bar titles, tab bar labels, alerts, etc.).
    static func apply() {
        let isArabic = Bundle.main.preferredLocalizations.first?.hasPrefix("ar") == true
        let family = isArabic ? "IBM Plex Sans Arabic" : "IBMPlexSans"

        func makeFont(size: CGFloat, weight: UIFont.Weight = .regular, style: UIFont.TextStyle = .body) -> UIFont {
            let descriptor = UIFontDescriptor(fontAttributes: [
                .family: family,
                .traits: [UIFontDescriptor.TraitKey.weight: weight.rawValue]
            ])
            let font = UIFont(descriptor: descriptor, size: size)
            return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        }

        // Navigation bar: large title + regular title
        let largeTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: makeFont(size: 34, weight: .bold, style: .largeTitle)
        ]
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: makeFont(size: 17, weight: .semibold, style: .headline)
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = largeTitleAttrs
        UINavigationBar.appearance().titleTextAttributes = titleAttrs

        // Tab bar item labels
        UITabBarItem.appearance().setTitleTextAttributes(
            [.font: makeFont(size: 10, weight: .medium, style: .caption2)], for: .normal
        )

        // Text fields and text views (for search bars, form inputs)
        UITextField.appearance().font = makeFont(size: 17, style: .body)
        UITextView.appearance().font = makeFont(size: 17, style: .body)
    }
}

// MARK: - App Theme

enum AppTheme {

    // MARK: Core Palette

    /// Primary brand color — teal-green, comfortable for buttons.
    static let primary = Color(
        light: Color(hex: 0x0A7E5A),   // deep teal-green for light mode
        dark: Color(hex: 0x30D158)     // Apple's system green (comfortable, not neon) for dark mode
    )

    /// Secondary — dark navy in light, cool cyan in dark.
    static let secondary = Color(
        light: Color(hex: 0x002E47),
        dark: Color(hex: 0x00D4FF)
    )

    /// Accent — mint green accent.
    static let accent = Color(
        light: Color(hex: 0x0D6E4E),
        dark: Color(hex: 0x34C759)   // Apple system green variant
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
