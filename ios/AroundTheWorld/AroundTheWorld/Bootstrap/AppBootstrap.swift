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

        BootLogger.step("2/4 auth check (deferred — no session store yet)")
        BootLogger.done("2/4 auth skipped (Phase 2)")

        BootLogger.step("3/4 Supabase client (not initialized at launch)")
        if AppEnvironment.supabaseURL == nil {
            BootLogger.step("3/4", "SUPABASE_URL unset — API uses Vapor base URL only")
        } else {
            BootLogger.step("3/4", "SUPABASE_URL present — Auth client deferred until sign-in")
        }
        BootLogger.done("3/4 Supabase deferred")

        BootLogger.step("4/4 location/MapKit (deferred until Map or Host tab)")
        BootLogger.done("4/4 location/MapKit deferred")
    }
}
