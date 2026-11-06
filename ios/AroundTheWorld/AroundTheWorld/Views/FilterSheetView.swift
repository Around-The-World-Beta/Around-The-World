import SwiftUI

/// Full-screen Filters sheet. Covers Matches entirely; drag down from the top to dismiss.
/// Motion matches the zip: 420ms `cubic-bezier(0.22, 1, 0.36, 1)`, dismiss past ~120pt.
struct FilterSheetView: View {
    @ObservedObject var viewModel: MatchesViewModel
    let screenHeight: CGFloat
    let onDismiss: () -> Void

    @State private var offsetY: CGFloat
    @State private var dragging = false
    @State private var scrollOffset: CGFloat = 0

    init(viewModel: MatchesViewModel, screenHeight: CGFloat, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.screenHeight = screenHeight
        self.onDismiss = onDismiss
        _offsetY = State(initialValue: screenHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            scrollBody
            footer
        }
        .background(AppTheme.card.ignoresSafeArea())
        .offset(y: max(0, offsetY))
        .animation(dragging ? nil : AppTheme.sheetAnimation, value: offsetY)
        .onAppear {
            offsetY = 0
        }
        .accessibilityAddTraits(.isModal)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(AppTheme.muted.opacity(0.35))
                .frame(width: 40, height: 6)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 12)

            Button(action: dismissSheet) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.filtersClose)
            .padding(.bottom, 20)

            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground)
                Text(L10n.filtersTitle)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(AppTheme.foreground)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(AppTheme.card)
        .contentShape(Rectangle())
        .gesture(headerDrag)
    }

    private var scrollBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                scrollOffsetProbe

                sectionTitle(L10n.filtersPreferredTime)
                    .padding(.top, 24)
                VStack(spacing: 4) {
                    ForEach(MatchTimeOfDay.allCases) { time in
                        checkboxRow(
                            title: time.label,
                            subtitle: time.rangeLabel,
                            isOn: viewModel.selectedTimes.contains(time)
                        ) {
                            viewModel.toggleTime(time)
                        }
                    }
                }
                .padding(.bottom, 24)

                divider

                HStack(alignment: .firstTextBaseline) {
                    sectionTitle(L10n.filtersDistance)
                    Spacer()
                    Text(L10n.filtersDistanceValue(Int(viewModel.radiusMiles.rounded())))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                }
                .padding(.top, 24)
                Text(L10n.filtersDistanceHelp)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.bottom, 20)
                Slider(value: $viewModel.radiusMiles, in: 0...50, step: 1)
                    .tint(AppTheme.gold)
                HStack {
                    Text("0")
                    Spacer()
                    Text("50")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .padding(.bottom, 24)

                divider

                sectionTitle(L10n.filtersDifficulty)
                    .padding(.top, 24)
                VStack(spacing: 4) {
                    ForEach(MatchDifficulty.allCases) { difficulty in
                        checkboxRow(
                            title: difficulty.rawValue,
                            subtitle: nil,
                            isOn: viewModel.selectedDifficulties.contains(difficulty)
                        ) {
                            viewModel.toggleDifficulty(difficulty)
                        }
                    }
                }
                .padding(.bottom, 96)
            }
            .padding(.horizontal, 20)
        }
        .coordinateSpace(name: "filterScroll")
        .scrollIndicators(.visible)
        .simultaneousGesture(scrollDismissDrag)
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Button(L10n.filtersClear) {
                viewModel.clearFilters()
            }
            .font(.body.weight(.bold))
            .foregroundStyle(AppTheme.foreground)

            Button(action: dismissSheet) {
                Text(L10n.filtersSeeGames(viewModel.filteredGames.count))
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppTheme.primaryForeground)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(AppTheme.gold, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(AppTheme.card)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 1)
        }
    }

    private var scrollOffsetProbe: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: FilterScrollOffsetKey.self,
                value: proxy.frame(in: .named("filterScroll")).minY
            )
        }
        .frame(height: 0)
        .onPreferenceChange(FilterScrollOffsetKey.self) { value in
            scrollOffset = value
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(AppTheme.foreground)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.border)
            .frame(height: 1)
    }

    private func checkboxRow(
        title: String,
        subtitle: String?,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(AppTheme.foreground)
                    if let subtitle {
                        Text("(\(subtitle))")
                            .font(.body)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isOn ? AppTheme.gold : Color.clear)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isOn ? AppTheme.gold : AppTheme.border, lineWidth: 2)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.primaryForeground)
                    }
                }
                .frame(width: 24, height: 24)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var headerDrag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                dragging = true
                offsetY = max(0, value.translation.height)
            }
            .onEnded { _ in
                finishDrag()
            }
    }

    private var scrollDismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard scrollOffset >= -1 else { return }
                let dy = value.translation.height
                if dy > 0 {
                    dragging = true
                    offsetY = dy
                }
            }
            .onEnded { _ in
                guard dragging else { return }
                finishDrag()
            }
    }

    private func finishDrag() {
        dragging = false
        if offsetY > 120 {
            dismissSheet()
        } else {
            offsetY = 0
        }
    }

    private func dismissSheet() {
        dragging = false
        offsetY = screenHeight
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            onDismiss()
        }
    }
}

private struct FilterScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
