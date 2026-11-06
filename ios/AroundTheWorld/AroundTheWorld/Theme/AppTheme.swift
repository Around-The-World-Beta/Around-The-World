import SwiftUI

/// Brand tokens from the approved Lovable black-and-gold screens.
/// Approximates the zip's oklch tokens (`--background 0.14`, `--primary 0.78 / hue 82`).
enum AppTheme {
    static let black = Color(red: 33 / 255, green: 30 / 255, blue: 27 / 255)
    static let white = Color(red: 247 / 255, green: 243 / 255, blue: 232 / 255)
    static let gold = Color(red: 226 / 255, green: 184 / 255, blue: 74 / 255)

    static let background = black
    static let card = Color(red: 48 / 255, green: 44 / 255, blue: 39 / 255)
    static let border = Color(red: 72 / 255, green: 65 / 255, blue: 54 / 255)
    static let primary = gold
    static let primaryForeground = black
    static let muted = Color(red: 173 / 255, green: 158 / 255, blue: 130 / 255)
    static let foreground = white
    static let secondaryFill = Color(red: 62 / 255, green: 56 / 255, blue: 48 / 255)
    /// Delete-account red from the Lovable settings list — not a neon system red.
    static let destructive = Color(red: 214 / 255, green: 92 / 255, blue: 78 / 255)

    /// Lovable `--radius` 0.75rem and `rounded-2xl` cards — not squircle / 24pt chrome.
    static let cardRadius: CGFloat = 16
    static let controlRadius: CGFloat = 12
    static let chipRadius: CGFloat = 6

    static let displayFont: Font = .system(size: 24, weight: .black)
    static let cardTitleFont: Font = .system(size: 17, weight: .black)
    static let sectionFont: Font = .system(size: 18, weight: .bold)

    static let sheetAnimation = Animation.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.42)
}

extension View {
    func atwScreenBackground() -> some View {
        self
            .background(AppTheme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

/// Press scale used on the gold FAB (`active:scale-90` in the zip).
struct ATWPressScaleStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.90

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
