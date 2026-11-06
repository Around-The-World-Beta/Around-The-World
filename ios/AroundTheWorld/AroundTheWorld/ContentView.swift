import SwiftUI

/// Root shell: Matches, My Games, Friends, floating Host "+", profile via the header avatar.
struct ContentView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var session: SessionStore
    @StateObject private var matchesViewModel = MatchesViewModel()
    @StateObject private var location = LocationPermissionService()
    @State private var tab: MainTab = .matches
    @State private var showHost = false
    @State private var showFilters = false
    @State private var filtersMounted = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    tabBody
                    MainTabBar(tab: $tab)
                }

                if !filtersMounted {
                    hostFab
                }

                if filtersMounted {
                    FilterSheetView(
                        viewModel: matchesViewModel,
                        screenHeight: geo.size.height,
                        onDismiss: {
                            filtersMounted = false
                            showFilters = false
                        }
                    )
                    .zIndex(40)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .tint(AppTheme.gold)
        .fullScreenCover(isPresented: $showHost) {
            HostSessionView()
                .environmentObject(session)
                .environmentObject(languageStore)
        }
        .sheet(isPresented: $session.isSignInPresented) {
            SignInView()
                .environmentObject(session)
        }
        .onChange(of: showFilters) { _, show in
            if show { filtersMounted = true }
        }
        .onChange(of: session.userID) { _, userID in
            languageStore.currentUserID = userID
        }
        .id(languageStore.language)
    }

    private var tabBody: some View {
        ZStack {
            MatchesDashboardView(
                viewModel: matchesViewModel,
                location: location,
                showFilters: $showFilters
            )
            .opacity(tab == .matches ? 1 : 0)
            .allowsHitTesting(tab == .matches)

            MyGamesView()
                .opacity(tab == .myGames ? 1 : 0)
                .allowsHitTesting(tab == .myGames)

            FriendsPlaceholderView()
                .opacity(tab == .friends ? 1 : 0)
                .allowsHitTesting(tab == .friends)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hostFab: some View {
        Button {
            if session.isSignedIn {
                showHost = true
            } else {
                session.requestSignIn()
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.primaryForeground)
                .frame(width: 56, height: 56)
                .background(AppTheme.gold, in: Circle())
                .shadow(color: AppTheme.gold.opacity(0.45), radius: 12)
        }
        .buttonStyle(ATWPressScaleStyle())
        .accessibilityLabel(L10n.hostTitle)
        .padding(.trailing, 20)
        .padding(.bottom, 88)
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageStore())
        .environmentObject(SessionStore.shared)
}
