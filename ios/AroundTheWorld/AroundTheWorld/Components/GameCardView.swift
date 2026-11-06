import SwiftUI
import CoreLocation

/// Card layout from the Lovable zip (`src/components/GameCard.tsx`).
struct GameCardView: View {
    let game: GameResponse
    var distanceMiles: Double? = nil
    var origin: CLLocationCoordinate2D? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerArt

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(AppTheme.cardTitleFont)
                            .italic()
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)
                            .lineLimit(2)
                        Text(distanceLine)
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

                fillBar

                HStack(spacing: 8) {
                    if let chip = distanceChipText {
                        distanceChip(chip)
                    }
                    chip(game.skill)
                    chip(game.format)
                    if game.isCancelled {
                        chip(L10n.myGamesCancelled)
                    }
                    Text(game.priceLabel.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.muted)
                }

                HStack(spacing: 8) {
                    Text(cardActionTitle)
                        .font(.headline.weight(.black))
                        .italic()
                        .foregroundStyle(cardActionMuted ? AppTheme.muted : AppTheme.primaryForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            cardActionMuted ? AppTheme.secondaryFill : AppTheme.primary,
                            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: cardActionMuted ? 1 : 0)
                        )

                    Text("DETAILS")
                        .font(.caption.weight(.bold))
                        .italic()
                        .foregroundStyle(AppTheme.foreground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            AppTheme.secondaryFill,
                            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
            }
            .padding(16)
        }
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var cardActionMuted: Bool {
        game.isCancelled || game.isFull
    }

    private var cardActionTitle: String {
        if game.isCancelled { return L10n.myGamesCancelled.uppercased() }
        return game.isFull ? "JOIN WAITLIST" : "JOIN MATCH"
    }

    private var distanceLine: String {
        if let origin {
            return game.distanceLine(from: origin)
        }
        return "\(game.neighborhood) · \(game.venue)"
    }

    private var distanceChipText: String? {
        if let origin {
            return game.distanceChip(from: origin)
        }
        if let distanceMiles {
            return distanceMiles < 10
                ? String(format: "%.1f mi", distanceMiles)
                : String(format: "%.0f mi", distanceMiles)
        }
        return nil
    }

    private var fillBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.secondaryFill)
                Capsule()
                    .fill(game.isFull ? AppTheme.muted : AppTheme.gold)
                    .frame(width: max(6, proxy.size.width * CGFloat(game.fillFraction)))
            }
        }
        .frame(height: 4)
    }

    private var headerArt: some View {
        ZStack(alignment: .topLeading) {
            artBackground
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .clipped()

            Text(game.startsInLabel.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AppTheme.background.opacity(0.80), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    @ViewBuilder
    private var artBackground: some View {
        if let urlString = game.imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .opacity(0.90)
                default:
                    pitchFallback
                }
            }
        } else {
            pitchFallback
        }
    }

    private var pitchFallback: some View {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.14, blue: 0.10),
                Color(red: 0.10, green: 0.09, blue: 0.07),
                AppTheme.gold.opacity(0.22),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "sportscourt")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(AppTheme.gold.opacity(0.28))
                .padding(16)
        }
    }

    private func distanceChip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AppTheme.primaryForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous))
    }

    private func chip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AppTheme.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.secondaryFill, in: RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}
