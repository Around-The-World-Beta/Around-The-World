import SwiftUI

/// Profile — header avatar, city · age, position pill, bio, stats, Settings card.
/// Reached from the header avatar. Layout follows the Lovable profile screen.
struct PlayerProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var languageStore: LanguageStore

    @State private var showEdit = false
    @State private var showSettings = false
    @State private var gamesPlayed = 0
    @State private var hostedCount = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if session.isRestoring {
                LoadingStateView(message: L10n.loadingMatches)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        statsRow
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                        settingsEntry
                            .padding(.horizontal, 20)
                            .padding(.bottom, 48)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .atwScreenBackground()
        .task {
            await session.reloadProfile()
            await loadStats()
        }
        .onChange(of: session.isSignedIn) { _, signedIn in
            if signedIn {
                Task {
                    await session.reloadProfile()
                    await loadStats()
                }
            } else {
                gamesPlayed = 0
                hostedCount = 0
            }
        }
        .fullScreenCover(isPresented: $showEdit) {
            EditProfileSheet()
                .environmentObject(session)
                .environmentObject(languageStore)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(session)
                .environmentObject(languageStore)
        }
        .alert(
            L10n.somethingBroke,
            isPresented: Binding(
                get: { session.lastError != nil && !session.isSignInPresented && !showEdit && !showSettings },
                set: { if !$0 { session.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.lastError = nil }
        } message: {
            Text(session.lastError ?? "")
        }
        .id(languageStore.language)
    }

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ProfileAvatarView(
                    name: session.user?.displayName,
                    avatarURL: session.profile?.httpAvatarURL,
                    size: 96,
                    goldBorder: true,
                    signedIn: session.isSignedIn
                )
                .padding(.top, 12)

                Text(displayName)
                    .font(.system(size: 30, weight: .black))
                    .italic()
                    .foregroundStyle(AppTheme.foreground)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                cityAgeLine
                    .padding(.top, 6)

                if session.isSignedIn {
                    skillPositionPill
                        .padding(.top, 12)
                }

                if session.isSignedIn, let bio = session.profile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.foreground.opacity(0.80))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 16)
                } else if !session.isSignedIn {
                    Text(L10n.authProfileSignedOut)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 16)

                    Button {
                        session.requestSignIn()
                    } label: {
                        Text(L10n.authSignIn.uppercased())
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.primaryForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(ATWPressScaleStyle())
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
            .background(AppTheme.card)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.border)
                    .frame(height: 1)
            }

            if session.isSignedIn {
                Button {
                    showEdit = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text(L10n.profileEdit)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.foreground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.card, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.top, 16)
                .accessibilityLabel(L10n.profileEditTitle)
            }
        }
    }

    private var displayName: String {
        if session.isSignedIn {
            let name = session.user?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? L10n.profileTitle : name
        }
        return L10n.profileTitle
    }

    @ViewBuilder
    private var cityAgeLine: some View {
        let city = session.profile?.city?.trimmingCharacters(in: .whitespacesAndNewlines)
        let age = session.profile?.age
        if session.isSignedIn, (city?.isEmpty == false || age != nil) {
            HStack(spacing: 4) {
                Image(systemName: "mappin")
                    .font(.system(size: 12, weight: .semibold))
                if let city, !city.isEmpty {
                    Text(city)
                }
                if let city, !city.isEmpty, let age {
                    Text("·")
                        .padding(.horizontal, 2)
                    Text(L10n.profileAgeYears(age))
                } else if let age {
                    Text(L10n.profileAgeYears(age))
                }
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.muted)
        }
    }

    @ViewBuilder
    private var skillPositionPill: some View {
        let skill = session.profile?.skillLevel
        let position = session.profile?.favoritePosition
        let positionLabel = position.flatMap { PlayerPosition(rawValue: $0)?.label } ?? position
        if let skill, !skill.isEmpty, let positionLabel, !positionLabel.isEmpty {
            Text("\(skill)  •  \(positionLabel)")
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(AppTheme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.card, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
        } else if let positionLabel, !positionLabel.isEmpty {
            Text(positionLabel)
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(AppTheme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.card, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(gamesPlayed)", label: L10n.profileGamesPlayed)
            statCard(value: "\(hostedCount)", label: L10n.profileHosted)
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(AppTheme.gold)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var settingsEntry: some View {
        Button {
            showSettings = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryForeground)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.secondaryFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.settingsTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.foreground)
                    Text(L10n.settingsSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(16)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.settingsTitle)
    }

    private func loadStats() async {
        guard session.isSignedIn, let userID = session.userID else {
            gamesPlayed = 0
            hostedCount = 0
            return
        }
        do {
            let games = try await AroundTheWorldAPI().listMyGames()
            hostedCount = games.filter { $0.hostUserId == userID }.count
            gamesPlayed = games.count
        } catch {
            BootLogger.fail("profile.stats", error)
        }
    }
}

extension ProfileResponse {
    var httpAvatarURL: URL? {
        guard let raw = avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }
}
