import SwiftUI

/// Game detail / Claim Spot — inspired by `src/routes/games.$gameId.tsx`.
struct GameDetailView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var languageStore: LanguageStore
    @StateObject private var viewModel: GameDetailViewModel
    @State private var editingGame: GameResponse?
    @State private var confirmCancel = false

    init(gameID: UUID) {
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(gameID: gameID))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            LoadableContent(
                state: viewModel.state,
                loadingMessage: L10n.loadingMatch,
                emptyTitle: L10n.emptyMatchesTitle,
                emptyMessage: L10n.emptyMatchesMessage,
                emptySystemImage: "questionmark.circle",
                onRetry: { Task { await viewModel.load() } }
            ) {
                if let game = viewModel.game {
                    detailScroll(game)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .atwScreenBackground()
        .task { await viewModel.load() }
        .onChange(of: session.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await viewModel.load() }
            }
        }
        .alert(
            "Match update",
            isPresented: Binding(
                get: { viewModel.actionMessage != nil },
                set: { if !$0 { viewModel.actionMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.actionMessage = nil }
        } message: {
            Text(viewModel.actionMessage ?? "")
        }
        .confirmationDialog(L10n.hostCancelGame, isPresented: $confirmCancel, titleVisibility: .visible) {
            Button(L10n.hostCancelGame, role: .destructive) {
                Task { await viewModel.cancelGame() }
            }
            Button(L10n.authCancel, role: .cancel) {}
        } message: {
            Text(L10n.hostCancelConfirm)
        }
        .fullScreenCover(item: $editingGame) { game in
            HostSessionView(existing: game)
                .environmentObject(session)
                .environmentObject(languageStore)
        }
        .onReceive(NotificationCenter.default.publisher(for: GamesDidChange.notification)) { _ in
            Task { await viewModel.load() }
        }
    }

    private func detailScroll(_ game: GameResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero(game)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 8) {
                        chip(game.skill)
                        chip(game.format)
                        if game.isCancelled {
                            chip(L10n.myGamesCancelled)
                        }
                        if viewModel.isHost {
                            chip(L10n.myGamesHosting)
                        }
                    }

                    Text(game.title)
                        .font(.system(size: 30, weight: .black))
                        .italic()
                        .foregroundStyle(AppTheme.foreground)
                        .textCase(.uppercase)
                        .tracking(-0.6)

                    Text("\(game.neighborhood) · \(game.venue)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        InfoTile(systemImage: "mappin.and.ellipse", label: "Venue", value: game.venue)
                        InfoTile(systemImage: "clock", label: "Kickoff", value: game.kickoffLabel)
                        InfoTile(
                            systemImage: "person.3.fill",
                            label: "Players",
                            value: "\(game.joinedCount)/\(game.capacity) joined"
                        )
                        InfoTile(systemImage: "dollarsign.circle", label: "Cost", value: game.priceLabel)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Host Notes")
                            .font(.caption.weight(.black))
                            .foregroundStyle(AppTheme.primary)
                            .textCase(.uppercase)
                        Text(game.notes.isEmpty ? "No notes from the host." : game.notes)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.foreground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                    participantsBlock

                    if viewModel.isHost {
                        hostActions(game)
                    } else {
                        claimButton(game)
                    }
                }
                .padding(20)
                .padding(.bottom, 72)
            }
        }
    }

    private func hero(_ game: GameResponse) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.35),
                    AppTheme.card,
                    AppTheme.background,
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .frame(height: 220)

            Text(game.shortKickoffLabel.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(16)
        }
    }

    private var participantsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Squad")
                .font(.caption.weight(.black))
                .foregroundStyle(AppTheme.muted)
                .textCase(.uppercase)

            if viewModel.participants.isEmpty {
                Text("No players listed yet — be the first to claim a spot.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(viewModel.participants) { participant in
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(AppTheme.primary)
                        Text(participant.userId.uuidString.prefix(8) + "…")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(AppTheme.foreground)
                        Spacer()
                        Text(participant.status.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func hostActions(_ game: GameResponse) -> some View {
        VStack(spacing: 10) {
            if game.isCancelled {
                Text(L10n.hostCancelledBanner)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else {
                Button {
                    editingGame = game
                } label: {
                    Text(L10n.hostEdit.uppercased())
                        .font(.title3.weight(.black))
                        .italic()
                        .foregroundStyle(AppTheme.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            AppTheme.secondaryFill,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.gold, lineWidth: 1)
                        )
                }
                .buttonStyle(ATWPressScaleStyle())
                .disabled(viewModel.isActing)

                Button {
                    confirmCancel = true
                } label: {
                    Group {
                        if viewModel.isActing {
                            ProgressView()
                                .tint(AppTheme.muted)
                        } else {
                            Text(L10n.hostCancelGame.uppercased())
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        AppTheme.card,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isActing)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func claimButton(_ game: GameResponse) -> some View {
        if game.isCancelled {
            Text(L10n.hostCancelledBanner)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        } else {
            let signedOut = !session.isSignedIn
            let waitlist = !signedOut && game.isFull
            Button {
                Task { await viewModel.claimSpot() }
            } label: {
                Group {
                    if viewModel.isActing {
                        ProgressView()
                            .tint(AppTheme.primaryForeground)
                    } else if signedOut {
                        Text(L10n.signInToClaim)
                    } else if waitlist {
                        Text(L10n.joinWaitlist)
                    } else {
                        Text(L10n.claimSpot(game.spotsLeft))
                    }
                }
                .font(.title3.weight(.black))
                .foregroundStyle(waitlist ? AppTheme.muted : AppTheme.primaryForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    waitlist ? AppTheme.secondaryFill : AppTheme.primary,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: waitlist ? 1 : 0)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isActing)
            .padding(.top, 4)
        }
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
