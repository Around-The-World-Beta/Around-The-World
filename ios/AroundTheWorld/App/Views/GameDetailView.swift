import SwiftUI
import AroundTheWorldKit

/// Game detail / Claim Spot — inspired by `src/routes/games.$gameId.tsx`.
struct GameDetailView: View {
    @StateObject private var viewModel: GameDetailViewModel

    init(gameID: UUID, currentUserID: UUID? = nil) {
        _viewModel = StateObject(
            wrappedValue: GameDetailViewModel(gameID: gameID, currentUserID: currentUserID)
        )
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            LoadableContent(
                state: viewModel.state,
                loadingMessage: "Loading match…",
                emptyTitle: "Game not found",
                emptyMessage: "This match may have been cancelled or removed.",
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
    }

    private func detailScroll(_ game: GameResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero(game)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 8) {
                        chip(game.skill)
                        chip(game.format)
                    }

                    Text(game.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.foreground)
                        .textCase(.uppercase)

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

                    claimButton(game)
                }
                .padding(20)
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

    private func claimButton(_ game: GameResponse) -> some View {
        Button {
            Task { await viewModel.claimSpot() }
        } label: {
            Group {
                if viewModel.isActing {
                    ProgressView()
                        .tint(AppTheme.primaryForeground)
                } else if game.isFull {
                    Text("JOIN WAITLIST")
                } else {
                    Text("CLAIM SPOT · \(game.spotsLeft) LEFT")
                }
            }
            .font(.title3.weight(.black))
            .foregroundStyle(game.isFull ? AppTheme.muted : AppTheme.primaryForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                game.isFull ? AppTheme.secondaryFill : AppTheme.primary,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: game.isFull ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isActing)
        .padding(.top, 4)
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
