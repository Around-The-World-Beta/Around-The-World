import SwiftUI
import Combine

/// Player profile scaffold — fields: age, skill tier, position, bio, based-in.
/// Visual layout will be rebuilt to match Lovable screenshots once shared (item 7).
struct PlayerProfileView: View {
    @StateObject private var viewModel = PlayerProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        BrandHeader()

                        Text(L10n.profileTitle)
                            .font(AppTheme.displayFont)
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)

                        Text(L10n.profilePendingLayout)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)

                        if let profile = viewModel.profile {
                            profileCard(profile)
                        } else {
                            EmptyStateView(
                                title: L10n.profileTitle,
                                message: L10n.profileEmpty,
                                systemImage: "person.crop.circle"
                            )
                            .frame(minHeight: 220)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }
        }
        .atwScreenBackground()
        .task { await viewModel.load() }
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

@MainActor
final class PlayerProfileViewModel: ObservableObject {
    @Published var profile: ProfileResponse?
    @Published var errorMessage: String?

    private let api = AroundTheWorldAPI()

    func load() async {
        // Until auth lands there is no current user — leave empty (no mock profile).
        profile = nil
        errorMessage = nil
        _ = api
    }
}
