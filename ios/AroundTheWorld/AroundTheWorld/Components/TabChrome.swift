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
    @EnvironmentObject private var session: SessionStore
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
                ProfileAvatarView(
                    name: session.user?.displayName,
                    avatarURL: session.profile?.httpAvatarURL,
                    size: 40,
                    goldBorder: session.isSignedIn,
                    signedIn: session.isSignedIn
                )
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

/// Circular avatar used in the header and on Profile. Falls back to an initial.
struct ProfileAvatarView: View {
    var name: String?
    var avatarURL: URL?
    var size: CGFloat = 40
    var goldBorder: Bool = false
    var signedIn: Bool = false

    var body: some View {
        Group {
            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(goldBorder ? AppTheme.gold : AppTheme.border, lineWidth: goldBorder ? 2 : 1)
        )
    }

    @ViewBuilder
    private var fallback: some View {
        if signedIn, let initial {
            Text(initial)
                .font(.system(size: size * 0.40, weight: .black))
                .foregroundStyle(AppTheme.primaryForeground)
                .frame(width: size, height: size)
                .background(AppTheme.gold, in: Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.92))
                .foregroundStyle(AppTheme.muted)
                .frame(width: size, height: size)
        }
    }

    private var initial: String? {
        guard let char = name?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return nil }
        return String(char).uppercased()
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
