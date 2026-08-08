import SwiftUI
import AroundTheWorldKit

/// Minimal smoke screen that proves the network stack can reach the Vapor API.
/// Phase 3 replaces this with the exact Matches / Map / Host / Friends layout.
struct ContentView: View {
    @State private var statusText = "Checking API…"
    @State private var games: [GameResponse] = []

    private let api = AroundTheWorldAPI()

    var body: some View {
        NavigationStack {
            List {
                Section("API") {
                    Text(statusText)
                }
                Section("Games") {
                    if games.isEmpty {
                        Text("No scheduled games yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(games) { game in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.title)
                                    .font(.headline)
                                Text("\(game.venue) · \(game.joinedCount)/\(game.capacity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Around The World")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    @MainActor
    private func refresh() async {
        do {
            let health = try await api.health()
            statusText = "\(health.service): \(health.status)"
            games = try await api.listGames()
        } catch {
            statusText = error.localizedDescription
            games = []
        }
    }
}
