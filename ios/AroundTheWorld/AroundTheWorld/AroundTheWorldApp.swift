import SwiftUI

/// Native iOS app entry point. Open `AroundTheWorld.xcodeproj` in Xcode and press Run.
@main
struct AroundTheWorldApp: App {
    /// Owned by SwiftUI (do not assign `LanguageStore.shared` into `@StateObject`).
    @StateObject private var languageStore = LanguageStore()

    init() {
        BootLogger.step("App.init — UI first; no location/MapKit/auth await")
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
