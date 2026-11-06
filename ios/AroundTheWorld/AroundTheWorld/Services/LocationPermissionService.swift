import Foundation
import CoreLocation
import Combine
import UIKit

/// Requests When-In-Use location **only** when Map / Host needs it — never during app launch.
@MainActor
final class LocationPermissionService: NSObject, ObservableObject {
    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var lastLocation: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var settingsSubtitle: String {
        switch authorization {
        case .authorizedAlways, .authorizedWhenInUse:
            return L10n.settingsLocationOn
        case .denied, .restricted:
            return L10n.settingsLocationDenied
        default:
            return L10n.settingsLocationOff
        }
    }

    func requestWhenInUseIfNeeded() {
        BootLogger.step("location.requestWhenInUse", "status=\(authorization.rawValue)")
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            BootLogger.step("location.denied_or_restricted")
        }
    }

    /// Settings row: ask once, or jump to iPhone Settings if the user already said no.
    func handleSettingsTap() {
        switch authorization {
        case .notDetermined:
            requestWhenInUseIfNeeded()
        case .denied, .restricted:
            openAppSettings()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            break
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension LocationPermissionService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorization = manager.authorizationStatus
            BootLogger.step("location.authChanged", "status=\(manager.authorizationStatus.rawValue)")
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            lastLocation = locations.last?.coordinate
            BootLogger.done("location.update")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            BootLogger.fail("location.update", error)
        }
    }
}
