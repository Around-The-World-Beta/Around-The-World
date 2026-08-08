import SwiftUI

struct LoadingStateView: View {
    var message: String = L10n.loadingMatches

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.primary)
                .scaleEffect(1.15)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ErrorStateView: View {
    let message: String
    var retryTitle: String = L10n.tryAgain
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.primary)
            Text(L10n.somethingBroke)
                .font(AppTheme.displayFont)
                .foregroundStyle(AppTheme.foreground)
                .textCase(.uppercase)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button(action: onRetry) {
                Text(retryTitle.uppercased())
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.primaryForeground)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyStateView: View {
    var title: String = L10n.emptyMatchesTitle
    var message: String = L10n.emptyMatchesMessage
    var systemImage: String = "sportscourt"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.primary.opacity(0.85))
            Text(title)
                .font(AppTheme.displayFont)
                .foregroundStyle(AppTheme.foreground)
                .textCase(.uppercase)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
