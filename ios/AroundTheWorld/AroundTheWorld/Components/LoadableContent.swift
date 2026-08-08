import SwiftUI

/// Renders loading / error / empty / content from a shared async load state.
struct LoadableContent<Content: View>: View {
    let state: LoadState
    var loadingMessage: String = "Loading…"
    var emptyTitle: String = "Nothing here yet"
    var emptyMessage: String = "Pull to refresh or check back soon."
    var emptySystemImage: String = "tray"
    let onRetry: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch state {
        case .idle:
            // Do not block the first frame on a forever spinner — `.task` flips to `.loading`.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading:
            LoadingStateView(message: loadingMessage)
        case .failed(let message):
            ErrorStateView(message: message, onRetry: onRetry)
        case .empty:
            EmptyStateView(
                title: emptyTitle,
                message: emptyMessage,
                systemImage: emptySystemImage
            )
        case .loaded:
            content()
        }
    }
}

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}
