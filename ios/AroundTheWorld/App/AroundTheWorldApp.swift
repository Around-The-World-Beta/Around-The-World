import SwiftUI
import AroundTheWorldKit

/// Root SwiftUI entry point.
/// 1. Create an iOS App target in Xcode
/// 2. Add the local `AroundTheWorldKit` package
/// 3. Add every file under `App/` to the app target
@main
struct AroundTheWorldApp: App {
    init() {
        // Default to local Vapor. Change for device / staging / Supabase-hosted API.
        Task {
            await NetworkManager.shared.setConfiguration(.localDevelopment)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .atwScreenBackground()
        }
    }
}
