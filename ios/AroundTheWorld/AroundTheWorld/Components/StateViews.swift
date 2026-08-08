import SwiftUI

struct LoadingStateView: View {
    var message: String = "Loading matches…"

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
    var retryTitle: String = "Try again"
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.primary)
            Text("Something broke")
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
    var title: String = "No matches yet"
    var message: String = "When games are posted, they’ll show up here."
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
