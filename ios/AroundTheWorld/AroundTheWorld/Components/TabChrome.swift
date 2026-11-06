import SwiftUI

/// Shared tab header: left-aligned italic title + muted subtitle, bell + avatar on the right.
struct TabHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.displayFont)
                    .italic()
                    .foregroundStyle(AppTheme.foreground)
                    .textCase(.uppercase)
                    .tracking(-0.6)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer(minLength: 8)
            HeaderActionsView()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

/// Bell + circular avatar. Avatar opens Profile. Bell is a honest placeholder (no push in 1.0).
struct HeaderActionsView: View {
    @State private var showNotificationsNote = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showNotificationsNote = true
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.card, in: Circle())
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.notificationsTitle)

            NavigationLink {
                PlayerProfileView()
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.muted)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.tabProfile)
        }
        .alert(L10n.notificationsTitle, isPresented: $showNotificationsNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.notificationsPlaceholder)
        }
    }
}

/// Three-tab bar matching the zip: Matches / My Games / Friends. No Map or Profile tabs.
struct MainTabBar: View {
    @Binding var tab: MainTab

    var body: some View {
        HStack {
            tabButton(.matches, title: L10n.tabMatches, systemImage: "trophy")
            Spacer()
            tabButton(.myGames, title: L10n.tabMyGames, systemImage: "calendar")
            Spacer()
            tabButton(.friends, title: L10n.tabFriends, systemImage: "person.2")
        }
        .padding(.horizontal, 32)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(AppTheme.card.opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 1)
        }
    }

    private func tabButton(_ value: MainTab, title: String, systemImage: String) -> some View {
        let active = tab == value
        return Button {
            tab = value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: active ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(-0.2)
            }
            .foregroundStyle(active ? AppTheme.gold : AppTheme.muted)
            .frame(minWidth: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : AccessibilityTraits())
    }
}

enum MainTab: Hashable {
    case matches
    case myGames
    case friends
}
