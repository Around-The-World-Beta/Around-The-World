import SwiftUI

/// Root tab shell for Bay Area beta: Matches, Map, Host, My Games, Profile/Settings.
struct ContentView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        TabView {
            MatchesDashboardView()
                .tabItem { Label(L10n.tabMatches, systemImage: "sportscourt") }

            SessionsMapView()
                .tabItem { Label(L10n.tabMap, systemImage: "map") }

            HostSessionView()
                .tabItem { Label(L10n.tabHost, systemImage: "plus.circle") }

            MyGamesView()
                .tabItem { Label(L10n.tabMyGames, systemImage: "calendar") }

            PlayerProfileView()
                .tabItem { Label(L10n.tabProfile, systemImage: "person.crop.circle") }
        }
        .tint(AppTheme.gold)
        .id(languageStore.language)
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageStore())
}
