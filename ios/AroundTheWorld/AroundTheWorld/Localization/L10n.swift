import Foundation

/// Thin localization layer. Keys live in `en.lproj` / `es.lproj` Localizable.strings.
/// Honors `LanguageStore` preference via UserDefaults (not only device locale).
enum L10n {
    private static let defaultsKey = "atw.language.preference"

    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        if args.isEmpty { return format }
        return String(format: format, locale: activeLocale, arguments: args)
    }

    private static var activeLocale: Locale {
        switch UserDefaults.standard.string(forKey: defaultsKey) {
        case "en": return Locale(identifier: "en")
        case "es": return Locale(identifier: "es")
        default: return Locale.autoupdatingCurrent
        }
    }

    private static var bundle: Bundle {
        let code: String
        switch UserDefaults.standard.string(forKey: defaultsKey) {
        case "en": code = "en"
        case "es": code = "es"
        default:
            let preferred = Locale.preferredLanguages.first ?? "en"
            code = preferred.hasPrefix("es") ? "es" : "en"
        }
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    static var tabMatches: String { tr("tab.matches") }
    static var tabMap: String { tr("tab.map") }
    static var tabHost: String { tr("tab.host") }
    static var tabMyGames: String { tr("tab.my_games") }
    static var tabProfile: String { tr("tab.profile") }
    static var tabSettings: String { tr("tab.settings") }

    static var loadingMatches: String { tr("loading.matches") }
    static var loadingMatch: String { tr("loading.match") }
    static var emptyMatchesTitle: String { tr("empty.matches.title") }
    static var emptyMatchesMessage: String { tr("empty.matches.message") }
    static var emptyMyGamesTitle: String { tr("empty.my_games.title") }
    static var emptyMyGamesMessage: String { tr("empty.my_games.message") }
    static var emptyMapTitle: String { tr("empty.map.title") }
    static var emptyMapMessage: String { tr("empty.map.message") }

    static var heroHeadline: String { tr("hero.headline") }
    static var heroSubtitle: String { tr("hero.subtitle") }
    static var freeSessions: String { tr("section.free") }
    static var paidSessions: String { tr("section.paid") }
    static func availableCount(_ n: Int) -> String { tr("section.available_count", n) }
    static var noFreeSessions: String { tr("section.no_free") }
    static var noPaidSessions: String { tr("section.no_paid") }

    static var settingsTitle: String { tr("settings.title") }
    static var settingsLanguage: String { tr("settings.language") }
    static var settingsLanguageSystem: String { tr("settings.language.system") }
    static var settingsLanguageEnglish: String { tr("settings.language.english") }
    static var settingsLanguageSpanish: String { tr("settings.language.spanish") }
    static var settingsAPIKeys: String { tr("settings.api_keys") }
    static func settingsMissingKeys(_ list: String) -> String { tr("settings.missing_keys", list) }
    static var settingsKeysOK: String { tr("settings.keys_ok") }

    static func claimSpot(_ left: Int) -> String { tr("action.claim_spot", left) }
    static var joinWaitlist: String { tr("action.join_waitlist") }
    static var tryAgain: String { tr("action.try_again") }
    static var somethingBroke: String { tr("error.something_broke") }
    static var signInToClaim: String { tr("auth.sign_in_to_claim") }

    static var hostTitle: String { tr("host.title") }
    static var hostSearchPlaceholder: String { tr("host.search_placeholder") }
    static var hostDropPin: String { tr("host.drop_pin") }
    static var hostSelectedLocation: String { tr("host.selected_location") }
    static var hostCreate: String { tr("host.create") }

    static var profileTitle: String { tr("profile.title") }
    static var profileAge: String { tr("profile.age") }
    static var profileSkill: String { tr("profile.skill") }
    static var profilePosition: String { tr("profile.position") }
    static var profileBio: String { tr("profile.bio") }
    static var profileBasedIn: String { tr("profile.based_in") }
    static var profileEmpty: String { tr("profile.empty") }
    static var profilePendingLayout: String { tr("profile.pending_layout") }

    static var mapTitle: String { tr("map.title") }
    static var logoPending: String { tr("brand.logo_pending") }
}
