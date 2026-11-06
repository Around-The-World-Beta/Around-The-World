import SwiftUI

/// Player profile scaffold — fields: age, skill tier, position, bio, based-in.
/// Visual layout will be rebuilt to match Lovable screenshots once shared (item 7).
struct PlayerProfileView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if session.isRestoring {
                LoadingStateView(message: L10n.loadingMatches)
            } else if !session.isSignedIn {
                SignedOutGateView(
                    title: L10n.profileTitle,
                    message: L10n.authProfileSignedOut,
                    systemImage: "person.crop.circle"
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(L10n.profileTitle)
                            .font(AppTheme.displayFont)
                            .italic()
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)

                        identityCard

                        if let profile = session.profile {
                            profileCard(profile)
                        }

                        Text(L10n.profilePendingLayout)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(AppTheme.gold)
                }
                .accessibilityLabel(L10n.tabSettings)
            }
        }
        .atwScreenBackground()
        .task { await session.reloadProfile() }
        .onChange(of: session.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await session.reloadProfile() }
            }
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.user?.displayName ?? L10n.profileTitle)
                .font(.title2.weight(.black))
                .foregroundStyle(AppTheme.foreground)
            if let email = session.user?.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func profileCard(_ profile: ProfileResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            field(L10n.profileAge, profile.age.map(String.init) ?? "—")
            field(L10n.profileSkill, profile.skillLevel ?? "—")
            field(L10n.profilePosition, profile.favoritePosition ?? "—")
            field(L10n.profileBasedIn, profile.city ?? "—")
            field(L10n.profileBio, profile.bio?.isEmpty == false ? (profile.bio ?? "—") : "—")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.gold)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.foreground)
        }
    }
}
