import SwiftUI

/// Native iOS app entry point. Open `AroundTheWorld.xcodeproj` in Xcode and press Run.
@main
struct AroundTheWorldApp: App {
    init() {
        // Simulator → Vapor on your Mac. For a physical device, switch to your Mac's LAN IP.
        Task {
            await NetworkManager.shared.setConfiguration(.iOSSimulatorLocal)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .atwScreenBackground()
        }
    }
}
