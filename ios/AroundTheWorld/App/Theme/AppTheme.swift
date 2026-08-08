import SwiftUI

/// Visual tokens inspired by the KickUp web prototype (dark base + gold accent).
/// Easy to restyle later when the product UI is updated.
enum AppTheme {
    static let background = Color(red: 0.09, green: 0.09, blue: 0.08)
    static let card = Color(red: 0.14, green: 0.13, blue: 0.12)
    static let border = Color(red: 0.24, green: 0.22, blue: 0.18)
    static let primary = Color(red: 0.90, green: 0.72, blue: 0.28)
    static let primaryForeground = Color(red: 0.09, green: 0.09, blue: 0.08)
    static let muted = Color(red: 0.62, green: 0.58, blue: 0.50)
    static let foreground = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let secondaryFill = Color(red: 0.18, green: 0.17, blue: 0.14)

    static let displayFont: Font = .system(.title2, design: .rounded).weight(.black)
    static let cardTitleFont: Font = .system(.title3, design: .rounded).weight(.heavy)
}

extension View {
    func atwScreenBackground() -> some View {
        self
            .background(AppTheme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}
