import SwiftUI
import UIKit

enum AppTheme {
    private static var appearance: AppAppearance {
        let raw = UserDefaults.standard.string(forKey: AppPreferenceKeys.appearance) ?? AppAppearance.dark.rawValue
        let configured = AppAppearance(rawValue: raw) ?? .dark
        if configured == .system {
            return UITraitCollection.current.userInterfaceStyle == .light ? .light : .dark
        }
        return configured
    }

    static var background: Color {
        switch appearance {
        case .system, .dark:
            return Color.black
        case .light:
            return Color(red: 0.98, green: 0.98, blue: 0.975)
        }
    }

    static var primaryText: Color {
        switch appearance {
        case .system, .dark:
            return Color.white
        case .light:
            return Color.black
        }
    }

    static var secondaryText: Color {
        switch appearance {
        case .system, .dark:
            return primaryText.opacity(0.7)
        case .light:
            return Color(red: 0.20, green: 0.20, blue: 0.22)
        }
    }

    static var tertiaryText: Color {
        switch appearance {
        case .system, .dark:
            return primaryText.opacity(0.45)
        case .light:
            return Color(red: 0.38, green: 0.38, blue: 0.40)
        }
    }

    static var cardFill: Color {
        switch appearance {
        case .system, .dark:
            return Color.white.opacity(0.06)
        case .light:
            return Color.white
        }
    }

    static var cardBorder: Color {
        switch appearance {
        case .system, .dark:
            return Color.white.opacity(0.14)
        case .light:
            return Color.black.opacity(0.14)
        }
    }

    static var accent: Color {
        primaryText
    }

    static var chipFill: Color {
        switch appearance {
        case .system, .dark:
            return Color.white.opacity(0.08)
        case .light:
            return Color.black.opacity(0.04)
        }
    }

    static var chipSelectedFill: Color {
        switch appearance {
        case .system, .dark:
            return Color.white.opacity(0.18)
        case .light:
            return Color.black.opacity(0.08)
        }
    }

    static var inputFill: Color {
        switch appearance {
        case .system, .dark:
            return Color.white.opacity(0.06)
        case .light:
            return Color.black.opacity(0.04)
        }
    }

    static var inputBorder: Color {
        switch appearance {
        case .system, .dark:
            return Color.white.opacity(0.14)
        case .light:
            return Color.black.opacity(0.18)
        }
    }
}
