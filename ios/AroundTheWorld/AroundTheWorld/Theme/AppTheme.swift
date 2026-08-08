import SwiftUI

/// Brand tokens from the Around the World identity system.
/// Black `#0D0D0D` · White `#FFFFFF` · Gold `#D4AF37`
enum AppTheme {
    static let black = Color(red: 0x0D / 255, green: 0x0D / 255, blue: 0x0D / 255)
    static let white = Color.white
    static let gold = Color(red: 0xD4 / 255, green: 0xAF / 255, blue: 0x37 / 255)

    static let background = black
    static let card = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let border = Color(red: 0.22, green: 0.22, blue: 0.22)
    static let primary = gold
    static let primaryForeground = black
    static let muted = Color(red: 0.70, green: 0.70, blue: 0.70)
    static let foreground = white
    static let secondaryFill = Color(red: 0.16, green: 0.16, blue: 0.16)

    /// Condensed bold display style (Gotham Condensed stand-in).
    static let displayFont: Font = .system(size: 28, weight: .heavy, design: .default).width(.condensed)
    static let cardTitleFont: Font = .system(size: 20, weight: .heavy, design: .default).width(.condensed)
    static let sectionFont: Font = .system(size: 18, weight: .bold, design: .default).width(.condensed)
}

extension View {
    func atwScreenBackground() -> some View {
        self
            .background(AppTheme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}
