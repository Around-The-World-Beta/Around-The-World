import SwiftUI
import MapKit

/// Host flow: MapKit search + pin-drop (no manual lat/lng entry).
struct HostSessionView: View {
    @StateObject private var location = LocationPermissionService()
    @StateObject private var search = LocationSearchCompleter()
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var pin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var venueName = ""
    @State private var neighborhood = ""
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.hostTitle)
                        .font(AppTheme.displayFont)
                        .foregroundStyle(AppTheme.foreground)
                        .textCase(.uppercase)

                    TextField(L10n.hostSearchPlaceholder, text: $query)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: query) { _, value in
                            search.update(query: value)
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
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Text(L10n.hostDropPin)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.muted)
                        .textCase(.uppercase)

                    MapReader { proxy in
                        Map(position: $position) {
                            Marker(venueName.isEmpty ? L10n.hostSelectedLocation : venueName, coordinate: pin)
                                .tint(AppTheme.gold)
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .onTapGesture { point in
                            if let coord = proxy.convert(point, from: .local) {
                                pin = coord
                                reverseGeocode(coord)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.hostSelectedLocation)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.gold)
                            .textCase(.uppercase)
                        Text(venueName.isEmpty ? "—" : venueName)
                            .foregroundStyle(AppTheme.foreground)
                        Text(neighborhood.isEmpty ? String(format: "%.4f, %.4f", pin.latitude, pin.longitude) : neighborhood)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))

                    Text(L10n.hostCreate)
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.primaryForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                        .opacity(0.45)
                        .overlay(alignment: .bottom) {
                            Text("Publish wires to API after auth (hostUserId). Location picker is ready.")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.muted)
                                .padding(.top, 8)
                                .offset(y: 28)
                        }
                        .padding(.bottom, 28)
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandHeader(compact: true)
                }
            }
        }
        .atwScreenBackground()
        .task {
            BootLogger.step("host.appear — requesting location (deferred from launch)")
            location.requestWhenInUseIfNeeded()
        }
    }

    private func selectCompletion(_ item: MKLocalSearchCompletion) async {
        query = item.title
        search.clear()
        let request = MKLocalSearch.Request(completion: item)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let mapItem = response.mapItems.first else { return }
            let coord = mapItem.placemark.coordinate
            pin = coord
            venueName = mapItem.name ?? item.title
            neighborhood = [
                mapItem.placemark.locality,
                mapItem.placemark.administrativeArea,
            ].compactMap { $0 }.joined(separator: ", ")
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
                venueName = mark.name ?? venueName
                neighborhood = [mark.locality, mark.administrativeArea].compactMap { $0 }.joined(separator: ", ")
            }
        }
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
