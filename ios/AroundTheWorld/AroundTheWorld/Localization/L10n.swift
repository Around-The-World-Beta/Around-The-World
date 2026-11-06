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
        Locale(identifier: resolvedLanguageCode)
    }

    private static var bundle: Bundle {
        let code = resolvedLanguageCode
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    /// Only English and Spanish have string catalogs. Other stored languages
    /// keep English copy until those translations ship.
    private static var resolvedLanguageCode: String {
        switch UserDefaults.standard.string(forKey: defaultsKey) {
        case "es": return "es"
        case "en": return "en"
        case nil:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("es") ? "es" : "en"
        default:
            return "en"
        }
    }

    static var tabMatches: String { tr("tab.matches") }
    static var tabMap: String { tr("tab.map") }
    static var tabHost: String { tr("tab.host") }
    static var tabMyGames: String { tr("tab.my_games") }
    static var tabFriends: String { tr("tab.friends") }
    static var tabProfile: String { tr("tab.profile") }
    static var tabSettings: String { tr("tab.settings") }

    static var matchesSubtitle: String { tr("matches.subtitle") }
    static var myGamesSubtitle: String { tr("my_games.subtitle") }
    static var friendsSubtitle: String { tr("friends.subtitle") }
    static var viewList: String { tr("view.list") }
    static var viewMap: String { tr("view.map") }
    static var dateToday: String { tr("date.today") }

    static var filtersTitle: String { tr("filters.title") }
    static var filtersClose: String { tr("filters.close") }
    static var filtersPreferredTime: String { tr("filters.preferred_time") }
    static var filtersDistance: String { tr("filters.distance") }
    static var filtersDistanceHelp: String { tr("filters.distance_help") }
    static func filtersDistanceValue(_ miles: Int) -> String { tr("filters.distance_value", miles) }
    static var filtersDifficulty: String { tr("filters.difficulty") }
    static var filtersClear: String { tr("filters.clear") }
    static func filtersSeeGames(_ n: Int) -> String {
        n == 1 ? tr("filters.see_game") : tr("filters.see_games", n)
    }
    static var filterMorning: String { tr("filters.morning") }
    static var filterAfternoon: String { tr("filters.afternoon") }
    static var filterEvening: String { tr("filters.evening") }
    static var filterLateNight: String { tr("filters.late_night") }
    static var filterMorningRange: String { tr("filters.morning.range") }
    static var filterAfternoonRange: String { tr("filters.afternoon.range") }
    static var filterEveningRange: String { tr("filters.evening.range") }
    static var filterLateNightRange: String { tr("filters.late_night.range") }

    static var sortLabel: String { tr("sort.label") }
    static var sortTime: String { tr("sort.time") }
    static var sortPrice: String { tr("sort.price") }
    static var sortDistance: String { tr("sort.distance") }
    static var sortDifficulty: String { tr("sort.difficulty") }

    static var friendsFollowing: String { tr("friends.following") }
    static var friendsFollowers: String { tr("friends.followers") }
    static var friendsPlaceholderTitle: String { tr("friends.placeholder.title") }
    static var friendsPlaceholderMessage: String { tr("friends.placeholder.message") }

    static var notificationsTitle: String { tr("notifications.title") }
    static var notificationsPlaceholder: String { tr("notifications.placeholder") }

    static var mapYou: String { tr("map.you") }
    static var mapTurnOnLocation: String { tr("map.turn_on_location") }
    static var mapLocationDenied: String { tr("map.location_denied") }
    static var mapLocationHelp: String { tr("map.location_help") }
    static var mapViewGame: String { tr("map.view_game") }
    static var hostClose: String { tr("host.close") }

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
    static var settingsAccount: String { tr("settings.account") }
    static var settingsSubtitle: String { tr("settings.subtitle") }
    static var settingsClose: String { tr("settings.close") }
    static var settingsLanguage: String { tr("settings.language") }
    static var settingsLanguageEnglish: String { tr("settings.language.english") }
    static var settingsLanguageSpanish: String { tr("settings.language.spanish") }
    static var settingsLanguageMandarin: String { tr("settings.language.mandarin") }
    static var settingsLanguageHindi: String { tr("settings.language.hindi") }
    static var settingsLanguageArabic: String { tr("settings.language.arabic") }
    static var settingsLanguagePortuguese: String { tr("settings.language.portuguese") }
    static var settingsLanguageFrench: String { tr("settings.language.french") }
    static var settingsLanguageGerman: String { tr("settings.language.german") }
    static var settingsLanguageJapanese: String { tr("settings.language.japanese") }
    static var settingsLanguageRussian: String { tr("settings.language.russian") }
    static var settingsLanguageKorean: String { tr("settings.language.korean") }
    static var settingsLanguageIndonesian: String { tr("settings.language.indonesian") }
    static var settingsLanguagePending: String { tr("settings.language.pending") }
    static var settingsLocation: String { tr("settings.location") }
    static var settingsLocationOn: String { tr("settings.location.on") }
    static var settingsLocationOff: String { tr("settings.location.off") }
    static var settingsLocationDenied: String { tr("settings.location.denied") }
    static var settingsNotifications: String { tr("settings.notifications") }
    static var settingsNotificationsSoon: String { tr("settings.notifications.soon") }
    static var settingsPayments: String { tr("settings.payments") }
    static var settingsPaymentsSubtitle: String { tr("settings.payments.subtitle") }
    static var settingsHelp: String { tr("settings.help") }
    static var settingsTerms: String { tr("settings.terms") }
    static var settingsPrivacy: String { tr("settings.privacy") }
    static var settingsLogOut: String { tr("settings.log_out") }

    static func claimSpot(_ left: Int) -> String { tr("action.claim_spot", left) }
    static var joinWaitlist: String { tr("action.join_waitlist") }
    static var tryAgain: String { tr("action.try_again") }
    static var somethingBroke: String { tr("error.something_broke") }
    static var signInToClaim: String { tr("auth.sign_in_to_claim") }
    static var authSignIn: String { tr("auth.sign_in") }
    static var authSignInWithApple: String { tr("auth.sign_in_with_apple") }
    static var authHeadline: String { tr("auth.headline") }
    static var authSubtitle: String { tr("auth.subtitle") }
    static var authPrivacyNote: String { tr("auth.privacy_note") }
    static var authKeepBrowsing: String { tr("auth.keep_browsing") }
    static var authClose: String { tr("auth.close") }
    static var authNotConfigured: String { tr("auth.not_configured") }
    static var authFailed: String { tr("auth.failed") }
    static var authSignInRequired: String { tr("auth.sign_in_required") }
    static var authSignOut: String { tr("auth.sign_out") }
    static var authSignOutConfirm: String { tr("auth.sign_out_confirm") }
    static var authDeleteAccount: String { tr("auth.delete_account") }
    static var authDeleteConfirm: String { tr("auth.delete_confirm") }
    static var authCancel: String { tr("auth.cancel") }
    static var authMyGamesSignedOut: String { tr("auth.my_games_signed_out") }
    static var authProfileSignedOut: String { tr("auth.profile_signed_out") }
    static var claimJoined: String { tr("claim.joined") }
    static var claimWaitlisted: String { tr("claim.waitlisted") }

    static var hostTitle: String { tr("host.title") }
    static var hostSearchPlaceholder: String { tr("host.search_placeholder") }
    static var hostDropPin: String { tr("host.drop_pin") }
    static var hostSelectedLocation: String { tr("host.selected_location") }
    static var hostCreate: String { tr("host.create") }
    static func hostAs(_ name: String) -> String { tr("host.as", name) }
    static var hostFieldTitle: String { tr("host.field.title") }
    static var hostFieldVenue: String { tr("host.field.venue") }
    static var hostFieldDate: String { tr("host.field.date") }
    static var hostFieldKickoff: String { tr("host.field.kickoff") }
    static var hostFieldFormat: String { tr("host.field.format") }
    static var hostFieldSkill: String { tr("host.field.skill") }
    static var hostFieldCapacity: String { tr("host.field.capacity") }
    static var hostFieldNotes: String { tr("host.field.notes") }
    static var hostTitlePlaceholder: String { tr("host.title.placeholder") }
    static var hostVenuePlaceholder: String { tr("host.venue.placeholder") }
    static var hostNotesPlaceholder: String { tr("host.notes.placeholder") }
    static var hostPost: String { tr("host.post") }
    static var hostSave: String { tr("host.save") }
    static var hostEditTitle: String { tr("host.edit.title") }
    static var hostEdit: String { tr("host.edit") }
    static var hostBayAreaOnly: String { tr("host.bay_area") }
    static var hostNeedTitle: String { tr("host.need_title") }
    static var hostNeedVenue: String { tr("host.need_venue") }
    static var hostNeedSignIn: String { tr("host.need_sign_in") }
    static var hostPostedTitle: String { tr("host.posted.title") }
    static var hostPostedMessage: String { tr("host.posted.message") }
    static var hostPostedBack: String { tr("host.posted.back") }
    static var hostUpdatedTitle: String { tr("host.updated.title") }
    static var hostUpdatedMessage: String { tr("host.updated.message") }
    static var hostUpdatedDone: String { tr("host.updated.done") }
    static var hostCancelGame: String { tr("host.cancel.game") }
    static var hostCancelConfirm: String { tr("host.cancel.confirm") }
    static var hostCancelledBanner: String { tr("host.cancelled") }
    static var hostCancelledDone: String { tr("host.cancelled.done") }
    static var hostPlayersUnit: String { tr("host.players_unit") }
    static var authHostSignedOut: String { tr("auth.host_signed_out") }
    static var myGamesHosting: String { tr("my_games.hosting") }
    static var myGamesCancelled: String { tr("my_games.cancelled") }

    static var profileTitle: String { tr("profile.title") }
    static var profileAge: String { tr("profile.age") }
    static var profileSkill: String { tr("profile.skill") }
    static var profilePosition: String { tr("profile.position") }
    static var profileBio: String { tr("profile.bio") }
    static var profileBasedIn: String { tr("profile.based_in") }
    static var profileEmpty: String { tr("profile.empty") }
    static var profileEdit: String { tr("profile.edit") }
    static var profileEditTitle: String { tr("profile.edit_title") }
    static var profileSave: String { tr("profile.save") }
    static var profileName: String { tr("profile.name") }
    static var profileCity: String { tr("profile.city") }
    static var profileCityPlaceholder: String { tr("profile.city_placeholder") }
    static var profileNamePlaceholder: String { tr("profile.name_placeholder") }
    static var profileBioPlaceholder: String { tr("profile.bio_placeholder") }
    static var profileChangePhoto: String { tr("profile.change_photo") }
    static var profilePhotoPending: String { tr("profile.photo_pending") }
    static var profileAddAge: String { tr("profile.add_age") }
    static func profileAgeYears(_ age: Int) -> String { tr("profile.age_years", age) }
    static func profileBioCount(_ n: Int) -> String { tr("profile.bio_count", n) }
    static var profileGamesPlayed: String { tr("profile.games_played") }
    static var profileHosted: String { tr("profile.hosted") }
    static var profilePositionGK: String { tr("profile.position.gk") }
    static var profilePositionDef: String { tr("profile.position.def") }
    static var profilePositionMid: String { tr("profile.position.mid") }
    static var profilePositionFwd: String { tr("profile.position.fwd") }
    static var profileNameTooShort: String { tr("profile.name_too_short") }

    static var mapTitle: String { tr("map.title") }
    static var logoPending: String { tr("brand.logo_pending") }
}
