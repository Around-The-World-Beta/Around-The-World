import Foundation
import CoreLocation

/// Nine-county Bay Area bbox — same numbers the server uses. Hosting outside this is rejected.
enum BayAreaMapBounds {
    static let minLatitude = 36.90
    static let maxLatitude = 38.85
    static let minLongitude = -123.15
    static let maxLongitude = -121.20

    static func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        (minLatitude...maxLatitude).contains(coordinate.latitude)
            && (minLongitude...maxLongitude).contains(coordinate.longitude)
    }
}

extension GameResponse {
    var isCancelled: Bool {
        status.compare("cancelled", options: [.caseInsensitive]) == .orderedSame
    }

    var isScheduled: Bool {
        status.compare("scheduled", options: [.caseInsensitive]) == .orderedSame
    }

    func isHostedBy(_ userID: UUID?) -> Bool {
        guard let userID else { return false }
        return hostUserId == userID
    }

    var priceLabel: String {
        if priceCents <= 0 { return "Free" }
        let dollars = Double(priceCents) / 100.0
        if priceCents % 100 == 0 {
            return "$\(priceCents / 100)/player"
        }
        return String(format: "$%.2f/player", dollars)
    }

    var isFull: Bool {
        joinedCount >= capacity
    }

    var spotsLeft: Int {
        max(capacity - joinedCount, 0)
    }

    var fillFraction: Double {
        guard capacity > 0 else { return 0 }
        return Double(min(joinedCount, capacity)) / Double(capacity)
    }

    var kickoffLabel: String {
        Self.kickoffFormatter.string(from: startsAt)
    }

    var shortKickoffLabel: String {
        Self.shortKickoffFormatter.string(from: startsAt)
    }

    var timeLabel: String {
        Self.timeFormatter.string(from: startsAt)
    }

    /// Card overlay: "Starts in 45m" when close, otherwise weekday + time.
    var startsInLabel: String {
        let minutes = Int(startsAt.timeIntervalSinceNow / 60)
        if minutes >= 0 && minutes <= 120 {
            if minutes < 1 { return "Starts now" }
            return "Starts in \(minutes)m"
        }
        return shortKickoffLabel
    }

    func distanceMiles(from origin: CLLocationCoordinate2D) -> Double {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        let there = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        return here.distance(from: there) / 1609.344
    }

    func distanceChip(from origin: CLLocationCoordinate2D) -> String {
        let miles = distanceMiles(from: origin)
        if miles < 10 {
            return String(format: "%.1f mi", miles)
        }
        return String(format: "%.0f mi", miles)
    }

    func distanceLine(from origin: CLLocationCoordinate2D) -> String {
        let miles = distanceMiles(from: origin)
        let formatted = miles < 10 ? String(format: "%.1f", miles) : String(format: "%.0f", miles)
        return "\(neighborhood) · \(formatted) miles away"
    }

    private static let kickoffFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE h:mm a"
        return formatter
    }()

    private static let shortKickoffFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE · h:mm a"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}
