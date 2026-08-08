import SwiftUI

/// Root navigation shell. Dashboard is the Matches list; detail pushes on tap.
/// Additional tabs (My Games / Friends) can land in a later UI pass.
struct ContentView: View {
    var body: some View {
        MatchesDashboardView()
    }
}

#Preview {
    ContentView()
}
