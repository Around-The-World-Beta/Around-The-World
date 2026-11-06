import Foundation

/// Ordered, non-blocking boot sequence.
///
/// Intentionally does **not** request location, initialize MapKit, or hit Auth/Supabase
/// on the main thread during `App.init`. Those run lazily when the user opens Map / Host /
/// Profile. The previous freeze was a main-thread-adjacent wait on `URLSession.shared`
/// (`waitsForConnectivity = true`) while the Matches screen awaited an unreachable API.
@MainActor
enum AppBootstrap {
    private(set) static var didConfigureNetwork = false

    static func configureAtLaunch() async {
        BootLogger.step("1/4 network config")
        let config = AppEnvironment.resolvedAPIConfiguration()
        await NetworkManager.shared.setConfiguration(config)
        didConfigureNetwork = true
        BootLogger.done("1/4 network → \(config.baseURL.absoluteString) timeout=\(Int(config.timeoutInterval))s")

        BootLogger.step("2/4 auth restore (Keychain, after first frame)")
        await NetworkManager.shared.setRefreshHandler { await AuthTokenBroker.refresh() }
        await SessionStore.shared.restoreIfNeeded()

        BootLogger.step("3/4 Supabase client")
        if AppEnvironment.supabaseURL == nil {
            BootLogger.step("3/4", "SUPABASE_URL unset — Sign in with Apple needs it in Xcode")
        } else {
            BootLogger.step("3/4", "SUPABASE_URL present")
        }
        BootLogger.done("3/4 Supabase ready for sign-in")

        BootLogger.step("4/4 location/MapKit (deferred until Map or Host tab)")
        BootLogger.done("4/4 location/MapKit deferred")
    }
}
