import Foundation

extension GameResponse {
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

    var kickoffLabel: String {
        Self.kickoffFormatter.string(from: startsAt)
    }

    var shortKickoffLabel: String {
        Self.shortKickoffFormatter.string(from: startsAt)
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
}
