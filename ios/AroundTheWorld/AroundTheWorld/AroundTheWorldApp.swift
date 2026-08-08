import SwiftUI

/// Native iOS app entry point. Open `AroundTheWorld.xcodeproj` in Xcode and press Run.
@main
struct AroundTheWorldApp: App {
    @StateObject private var languageStore = LanguageStore.shared

    init() {
        BootLogger.step("App.init — UI first; no location/MapKit/auth await")
        // Network config is applied asynchronously in AppBootstrap — never blocks first frame.
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.locale)
                .atwScreenBackground()
                .id(languageStore.language)
                .task {
                    await AppBootstrap.configureAtLaunch()
                }
        }
    }
}
