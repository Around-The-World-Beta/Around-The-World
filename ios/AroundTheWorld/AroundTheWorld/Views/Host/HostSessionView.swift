import SwiftUI
import MapKit

/// Host a game — form from the Lovable zip, venue search + pin from the existing native flow.
struct HostSessionView: View {
    @StateObject private var viewModel: HostSessionViewModel
    @StateObject private var location = LocationPermissionService()
    @StateObject private var search = LocationSearchCompleter()
    @State private var position: MapCameraPosition
    @State private var skipNextSearch = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore

    init(existing: GameResponse? = nil) {
        _viewModel = StateObject(wrappedValue: HostSessionViewModel(existing: existing))
        if let existing {
            _position = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: existing.latitude, longitude: existing.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
            ))
        } else {
            _position = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            ))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.isRestoring {
                    LoadingStateView(message: L10n.loadingMatches)
                } else if !session.isSignedIn {
                    SignedOutGateView(
                        title: L10n.hostTitle,
                        message: L10n.authHostSignedOut,
                        systemImage: "plus.circle"
                    )
                } else if viewModel.postedGame != nil {
                    postedConfirmation
                } else {
                    formScroll
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: viewModel.postedGame == nil ? "arrow.left" : "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.foreground)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.card, in: Circle())
                            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                    }
                    .accessibilityLabel(L10n.hostClose)
                }
                ToolbarItem(placement: .principal) {
                    if viewModel.postedGame == nil {
                        Text(viewModel.isEditing ? L10n.hostEditTitle : L10n.hostTitle)
                            .font(AppTheme.displayFont)
                            .italic()
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)
                            .tracking(-0.4)
                            .lineLimit(1)
                    }
                }
            }
            .toolbarBackground(AppTheme.background.opacity(0.90), for: .navigationBar)
        }
        .atwScreenBackground()
        .interactiveDismissDisabled(viewModel.isPublishing)
        .task {
            BootLogger.step("host.appear — requesting location (deferred from launch)")
            location.requestWhenInUseIfNeeded()
        }
    }

    private var formScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hostField(L10n.hostFieldTitle) {
                    TextField(L10n.hostTitlePlaceholder, text: $viewModel.title)
                        .hostTextFieldChrome()
                }

                hostField(L10n.hostFieldVenue) {
                    TextField(L10n.hostVenuePlaceholder, text: $viewModel.venueName)
                        .hostTextFieldChrome()
                        .onChange(of: viewModel.venueName) { _, value in
                            if skipNextSearch {
                                skipNextSearch = false
                                return
                            }
                            search.update(query: value)
                        }
                }

                if !search.results.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(search.results.enumerated()), id: \.offset) { _, item in
                            Button {
                                Task { await selectCompletion(item) }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .foregroundStyle(AppTheme.foreground)
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(AppTheme.border)
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }

                Text(L10n.hostDropPin)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .textCase(.uppercase)
                    .tracking(1.4)

                MapReader { proxy in
                    Map(position: $position) {
                        Marker(
                            viewModel.venueName.isEmpty ? L10n.hostSelectedLocation : viewModel.venueName,
                            coordinate: viewModel.pin
                        )
                        .tint(AppTheme.gold)
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .onTapGesture { point in
                        if let coord = proxy.convert(point, from: .local) {
                            viewModel.dropPin(coord)
                            reverseGeocode(coord)
                        }
                    }
                }

                selectedLocationCard

                if !viewModel.isInBayArea {
                    Text(L10n.hostBayAreaOnly)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 12) {
                    hostField(L10n.hostFieldDate) {
                        DatePicker("", selection: $viewModel.startsAt, displayedComponents: .date)
                            .labelsHidden()
                            .tint(AppTheme.gold)
                            .colorScheme(.dark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                AppTheme.card,
                                in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    }
                    hostField(L10n.hostFieldKickoff) {
                        DatePicker("", selection: $viewModel.startsAt, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(AppTheme.gold)
                            .colorScheme(.dark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                AppTheme.card,
                                in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    }
                }

                hostField(L10n.hostFieldFormat) {
                    chipWrap(options: HostSessionViewModel.formats, selection: $viewModel.format) { $0 }
                }

                hostField(L10n.hostFieldSkill) {
                    chipWrap(options: Array(MatchDifficulty.allCases), selection: $viewModel.skill) { $0.rawValue }
                }

                hostField(L10n.hostFieldCapacity) {
                    capacityStepper
                }

                hostField(L10n.hostFieldNotes) {
                    VStack(alignment: .trailing, spacing: 6) {
                        TextField(L10n.hostNotesPlaceholder, text: $viewModel.notes, axis: .vertical)
                            .lineLimit(3...6)
                            .hostTextFieldChrome()
                            .onChange(of: viewModel.notes) { _, next in
                                if next.count > UserContentLimits.notesMax {
                                    viewModel.notes = UserContentLimits.clamped(
                                        next,
                                        maxLength: UserContentLimits.notesMax
                                    )
                                }
                            }
                        Text(L10n.hostNotesCount(viewModel.notes.count))
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                if let name = session.user?.displayName, !name.isEmpty {
                    Text(L10n.hostAs(name))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    Group {
                        if viewModel.isPublishing {
                            ProgressView()
                                .tint(AppTheme.primaryForeground)
                        } else {
                            Text((viewModel.isEditing ? L10n.hostSave : L10n.hostPost).uppercased())
                        }
                    }
                    .font(.system(size: 20, weight: .black))
                    .italic()
                    .foregroundStyle(AppTheme.primaryForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    .shadow(color: AppTheme.gold.opacity(0.35), radius: 10)
                }
                .buttonStyle(ATWPressScaleStyle(pressedScale: 0.95))
                .disabled(viewModel.isPublishing)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var postedConfirmation: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppTheme.primaryForeground)
                .frame(width: 64, height: 64)
                .background(AppTheme.gold, in: Circle())
                .shadow(color: AppTheme.gold.opacity(0.45), radius: 12)

            Text((viewModel.isEditing ? L10n.hostUpdatedTitle : L10n.hostPostedTitle).uppercased())
                .font(.system(size: 30, weight: .black))
                .italic()
                .foregroundStyle(AppTheme.foreground)
                .padding(.top, 20)

            Text(viewModel.isEditing ? L10n.hostUpdatedMessage : L10n.hostPostedMessage)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.top, 8)

            Button {
                dismiss()
            } label: {
                Text((viewModel.isEditing ? L10n.hostUpdatedDone : L10n.hostPostedBack).uppercased())
                    .font(.system(size: 18, weight: .black))
                    .italic()
                    .foregroundStyle(AppTheme.primaryForeground)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
            }
            .buttonStyle(ATWPressScaleStyle(pressedScale: 0.95))
            .padding(.top, 24)
            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var selectedLocationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.hostSelectedLocation)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.gold)
                .textCase(.uppercase)
                .tracking(1.4)
            Text(viewModel.venueName.isEmpty ? "—" : viewModel.venueName)
                .foregroundStyle(AppTheme.foreground)
            Text(
                viewModel.neighborhood.isEmpty
                    ? String(format: "%.4f, %.4f", viewModel.pin.latitude, viewModel.pin.longitude)
                    : viewModel.neighborhood
            )
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var capacityStepper: some View {
        HStack(spacing: 16) {
            capacityButton(systemImage: "minus") {
                viewModel.bumpCapacity(-1)
            }
            Text("\(viewModel.capacity)")
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.foreground)
                .frame(minWidth: 36)
            capacityButton(systemImage: "plus") {
                viewModel.bumpCapacity(1)
            }
            Text(L10n.hostPlayersUnit)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func capacityButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.primaryForeground)
                .frame(width: 32, height: 32)
                .background(AppTheme.gold, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func hostField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .textCase(.uppercase)
                .tracking(1.4)
            content()
        }
    }

    private func chipWrap<T: Hashable>(
        options: [T],
        selection: Binding<T>,
        label: @escaping (T) -> String
    ) -> some View {
        HostFlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = selection.wrappedValue == option
                Button {
                    selection.wrappedValue = option
                } label: {
                    Text(label(option))
                        .font(.system(size: 14, weight: .black))
                        .italic()
                        .foregroundStyle(selected ? AppTheme.primaryForeground : AppTheme.muted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selected ? AppTheme.gold : AppTheme.card,
                            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(selected ? AppTheme.gold : AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func selectCompletion(_ item: MKLocalSearchCompletion) async {
        search.clear()
        let request = MKLocalSearch.Request(completion: item)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let mapItem = response.mapItems.first else { return }
            let coord = mapItem.placemark.coordinate
            let name = mapItem.name ?? item.title
            let area = [
                mapItem.placemark.locality,
                mapItem.placemark.administrativeArea,
            ].compactMap { $0 }.joined(separator: ", ")
            skipNextSearch = true
            viewModel.applyVenue(name: name, neighborhood: area, coordinate: coord)
            position = .region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
            )
        } catch {
            BootLogger.fail("host.search", error)
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { marks, _ in
            guard let mark = marks?.first else { return }
            DispatchQueue.main.async {
                skipNextSearch = true
                let name = mark.name ?? viewModel.venueName
                let area = [mark.locality, mark.administrativeArea].compactMap { $0 }.joined(separator: ", ")
                viewModel.applyVenue(
                    name: name.isEmpty ? viewModel.venueName : name,
                    neighborhood: area,
                    coordinate: coord
                )
            }
        }
    }
}

/// Wraps chips the way the zip does (`flex-wrap gap-2`) so "Open to All" is not cramped.
private struct HostFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? 0, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placed = arrange(in: bounds.width, subviews: subviews).frames
        for (index, subview) in subviews.enumerated() {
            guard placed.indices.contains(index) else { continue }
            let frame = placed[index].offsetBy(dx: bounds.minX, dy: bounds.minY)
            subview.place(at: frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrange(in width: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let wrapping = width > 0
        let limit = wrapping ? width : CGFloat.greatestFiniteMagnitude
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if wrapping, x + size.width > limit, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        let usedWidth = frames.map(\.maxX).max() ?? 0
        let usedHeight = frames.map(\.maxY).max() ?? 0
        return (CGSize(width: wrapping ? width : usedWidth, height: usedHeight), frames)
    }
}

private extension View {
    func hostTextFieldChrome() -> some View {
        self
            .font(.subheadline)
            .foregroundStyle(AppTheme.foreground)
            .tint(AppTheme.gold)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                AppTheme.card,
                in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

@MainActor
final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 1.2, longitudeDelta: 1.2)
        )
    }

    func update(query: String) {
        completer.queryFragment = query
    }

    func clear() {
        results = []
        completer.queryFragment = ""
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let items = completer.results
        Task { @MainActor in
            results = items
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            BootLogger.fail("host.completer", error)
            results = []
        }
    }
}
