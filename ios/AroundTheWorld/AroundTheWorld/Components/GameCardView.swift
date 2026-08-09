import SwiftUI

/// Card layout inspired by `src/components/GameCard.tsx`.
struct GameCardView: View {
    let game: GameResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerArt

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(AppTheme.cardTitleFont)
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)
                            .lineLimit(2)
                        Text("\(game.neighborhood) · \(game.venue)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(game.joinedCount)/\(game.capacity)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(game.isFull ? AppTheme.muted : AppTheme.primary)
                        Text(game.isFull ? "FULL" : "PLAYERS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                HStack(spacing: 8) {
                    chip(game.skill)
                    chip(game.format)
                    Text(game.priceLabel.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                }

                HStack(spacing: 8) {
                    Text(game.isFull ? "JOIN WAITLIST" : "JOIN MATCH")
                        .font(.headline.weight(.black))
                        .foregroundStyle(game.isFull ? AppTheme.muted : AppTheme.primaryForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            game.isFull ? AppTheme.secondaryFill : AppTheme.primary,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: game.isFull ? 1 : 0)
                        )

                    Text("DETAILS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.foreground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.secondaryFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
            }
            .padding(16)
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var headerArt: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    AppTheme.secondaryFill,
                    AppTheme.card,
                    AppTheme.primary.opacity(0.25),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity)
            .frame(height: 120)

            Text(game.shortKickoffLabel.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func chip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AppTheme.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.secondaryFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}
