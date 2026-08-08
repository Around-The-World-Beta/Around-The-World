import Foundation

/// Bay Area beta geographic bounds (approx. SF Bay + Peninsula + East Bay + South Bay).
enum BayAreaRegion {
    static let minLatitude = 36.85
    static let maxLatitude = 38.55
    static let minLongitude = -123.15
    static let maxLongitude = -121.45

    static func contains(latitude: Double, longitude: Double) -> Bool {
        (minLatitude...maxLatitude).contains(latitude)
            && (minLongitude...maxLongitude).contains(longitude)
    }
}
