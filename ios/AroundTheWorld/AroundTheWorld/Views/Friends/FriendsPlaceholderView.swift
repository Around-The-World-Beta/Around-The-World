import SwiftUI

/// Friends tab chrome matching Matches / My Games. Following graph is W7 / 1.1.
struct FriendsPlaceholderView: View {
    @State private var pane: Pane = .following

    private enum Pane: String, CaseIterable {
        case following
        case followers
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: L10n.tabFriends, subtitle: L10n.friendsSubtitle)

                paneToggle
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                EmptyStateView(
                    title: L10n.friendsPlaceholderTitle,
                    message: L10n.friendsPlaceholderMessage,
                    systemImage: "person.2"
                )
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .atwScreenBackground()
    }

    private var paneToggle: some View {
        HStack(spacing: 0) {
            paneButton(.following, title: L10n.friendsFollowing)
            paneButton(.followers, title: L10n.friendsFollowers)
        }
        .padding(4)
        .background(AppTheme.secondaryFill, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
    }

    private func paneButton(_ value: Pane, title: String) -> some View {
        let active = pane == value
        return Button {
            pane = value
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(active ? AppTheme.primaryForeground : AppTheme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(active ? AppTheme.gold : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
