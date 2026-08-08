import SwiftUI

/// Detail metric tile inspired by `games.$gameId.tsx` InfoTile.
struct InfoTile: View {
    let systemImage: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(AppTheme.muted)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.foreground)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
