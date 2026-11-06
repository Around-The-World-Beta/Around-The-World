import Foundation
import CoreLocation
import Combine

enum MatchViewMode: String, CaseIterable {
    case list
    case map
}

enum MatchSortKey: String, CaseIterable, Identifiable {
    case time
    case price
    case distance
    case difficulty

    var id: String { rawValue }

    var label: String {
        switch self {
        case .time: return L10n.sortTime
        case .price: return L10n.sortPrice
        case .distance: return L10n.sortDistance
        case .difficulty: return L10n.sortDifficulty
        }
    }
}

enum MatchTimeOfDay: String, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case lateNight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .morning: return L10n.filterMorning
        case .afternoon: return L10n.filterAfternoon
        case .evening: return L10n.filterEvening
        case .lateNight: return L10n.filterLateNight
        }
    }

    var rangeLabel: String {
        switch self {
        case .morning: return L10n.filterMorningRange
        case .afternoon: return L10n.filterAfternoonRange
        case .evening: return L10n.filterEveningRange
        case .lateNight: return L10n.filterLateNightRange
        }
    }

    static func bucket(for date: Date, calendar: Calendar = .current) -> MatchTimeOfDay {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let minutes = hour * 60 + minute
        if minutes >= 22 * 60 || minutes < 2 * 60 { return .lateNight }
        if minutes < 12 * 60 { return .morning }
        if minutes < 17 * 60 { return .afternoon }
        return .evening
    }
}

/// Canonical skill tiers from W0 / the Lovable zip. Never surface "Beginner".
enum MatchDifficulty: String, CaseIterable, Identifiable {
    case casual = "Casual"
    case intermediate = "Intermediate"
    case baller = "Baller"
    case openToAll = "Open to All"

    var id: String { rawValue }
    var rank: Int {
        switch self {
        case .casual: return 0
        case .intermediate: return 1
        case .baller: return 2
        case .openToAll: return 3
        }
    }

    static func canonical(_ raw: String) -> MatchDifficulty {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "beginner", "casual": return .casual
        case "intermediate": return .intermediate
        case "advanced", "baller": return .baller
        case "open to all": return .openToAll
        default: return .casual
        }
    }
}

struct MatchDay: Identifiable, Equatable {
    let date: Date
    var id: Date { date }
    let weekday: String
    let dayNumber: Int
    let month: String
    let isToday: Bool

    static func buildWeek(now: Date = Date(), calendar: Calendar = .current) -> [MatchDay] {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.dateFormat = "EEE"
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "en_US_POSIX")
        monthFormatter.dateFormat = "MMM"

        let today = calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset -> MatchDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return MatchDay(
                date: date,
                weekday: weekdayFormatter.string(from: date),
                dayNumber: calendar.component(.day, from: date),
                month: monthFormatter.string(from: date),
                isToday: offset == 0
            )
        }
    }
}

/// Fetches live Bay Area browse listings (open spots only) and applies Matches filters locally.
@MainActor
final class MatchesViewModel: ObservableObject {
    static let bayAreaOrigin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    static let defaultRadiusMiles: Double = 10

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var games: [GameResponse] = []
    @Published private(set) var lastRefreshed: Date?

    @Published var viewMode: MatchViewMode = .list
    @Published var selectedDayIndex: Int = 0
    @Published var sort: MatchSortKey = .time
    @Published var selectedTimes: Set<MatchTimeOfDay> = []
    @Published var selectedDifficulties: Set<MatchDifficulty> = []
    @Published var radiusMiles: Double = MatchesViewModel.defaultRadiusMiles
    @Published var origin: CLLocationCoordinate2D = MatchesViewModel.bayAreaOrigin

    private let api: AroundTheWorldAPI
    private let calendar = Calendar.current

    init(api: AroundTheWorldAPI = AroundTheWorldAPI()) {
        self.api = api
    }

    var week: [MatchDay] {
        MatchDay.buildWeek(calendar: calendar)
    }

    var selectedDay: MatchDay {
        let days = week
        guard days.indices.contains(selectedDayIndex) else { return days[0] }
        return days[selectedDayIndex]
    }

    var activeFilterCount: Int {
        var count = selectedTimes.count + selectedDifficulties.count
        if abs(radiusMiles - Self.defaultRadiusMiles) > 0.5 {
            count += 1
        }
        return count
    }

    var filteredGames: [GameResponse] {
        let day = selectedDay
        let origin = self.origin
        let times = selectedTimes
        let diffs = selectedDifficulties
        let radius = radiusMiles
        let sort = self.sort

        var result = games.filter { game in
            guard calendar.isDate(game.startsAt, inSameDayAs: day.date) else { return false }
            if game.distanceMiles(from: origin) > radius { return false }
            if !times.isEmpty, !times.contains(MatchTimeOfDay.bucket(for: game.startsAt, calendar: calendar)) {
                return false
            }
            if !diffs.isEmpty,
               !diffs.contains(.openToAll),
               !diffs.contains(MatchDifficulty.canonical(game.skill)) {
                return false
            }
            return true
        }

        result.sort { lhs, rhs in
            let comparison: Bool
            switch sort {
            case .price:
                comparison = lhs.priceCents == rhs.priceCents
                    ? lhs.startsAt < rhs.startsAt
                    : lhs.priceCents < rhs.priceCents
            case .distance:
                let ld = lhs.distanceMiles(from: origin)
                let rd = rhs.distanceMiles(from: origin)
                comparison = ld == rd ? lhs.startsAt < rhs.startsAt : ld < rd
            case .difficulty:
                let lr = MatchDifficulty.canonical(lhs.skill).rank
                let rr = MatchDifficulty.canonical(rhs.skill).rank
                comparison = lr == rr ? lhs.startsAt < rhs.startsAt : lr < rr
            case .time:
                comparison = lhs.startsAt == rhs.startsAt
                    ? lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                    : lhs.startsAt < rhs.startsAt
            }
            return comparison
        }
        return result
    }

    var freeGames: [GameResponse] {
        filteredGames.filter { $0.priceCents == 0 }
    }

    var paidGames: [GameResponse] {
        filteredGames.filter { $0.priceCents > 0 }
    }

    func toggleTime(_ time: MatchTimeOfDay) {
        if selectedTimes.contains(time) {
            selectedTimes.remove(time)
        } else {
            selectedTimes.insert(time)
        }
    }

    func toggleDifficulty(_ difficulty: MatchDifficulty) {
        if selectedDifficulties.contains(difficulty) {
            selectedDifficulties.remove(difficulty)
        } else {
            selectedDifficulties.insert(difficulty)
        }
    }

    func clearFilters() {
        selectedTimes = []
        selectedDifficulties = []
        radiusMiles = Self.defaultRadiusMiles
    }

    /// After a host publishes, land on that day and make sure distance filters are not hiding it.
    func reveal(_ game: GameResponse) {
        let days = week
        if let idx = days.firstIndex(where: { calendar.isDate(game.startsAt, inSameDayAs: $0.date) }) {
            selectedDayIndex = idx
        }
        selectedTimes = []
        selectedDifficulties = []
        let miles = game.distanceMiles(from: origin)
        if miles > radiusMiles {
            radiusMiles = min(50, ceil(miles + 0.5))
        }
    }

    func load(force: Bool = false) async {
        if case .loading = state, !force { return }

        BootLogger.step("matches.load.start")
        state = .loading
        do {
            let fetched = try await api.listGames(includeFull: false, region: "bay-area")
            games = fetched
            lastRefreshed = Date()
            state = fetched.isEmpty ? .empty : .loaded
            BootLogger.done("matches.load (\(fetched.count) open)")
        } catch {
            games = []
            state = .failed(error.localizedDescription)
            BootLogger.fail("matches.load", error)
        }
    }
}
