import SwiftUI

/// In-app brand lockup: logo mark + wordmark treatment.
struct BrandHeader: View {
    var subtitle: String = "Find. Play. Connect."
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            Image("LogoMark")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 28 : 44, height: compact ? 28 : 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("AROUND")
                        .foregroundStyle(AppTheme.white)
                    Text("THE")
                        .font(.system(size: compact ? 9 : 11, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                    Text("WORLD")
                        .foregroundStyle(AppTheme.gold)
                }
                .font(compact ? AppTheme.sectionFont : AppTheme.cardTitleFont)
                .textCase(.uppercase)

                if !compact {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            if !compact {
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Around the World")
    }
}
