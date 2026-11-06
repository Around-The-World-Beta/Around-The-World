import Foundation
import SwiftUI
import Combine

/// The twelve languages from the approved settings list.
/// English and Spanish switch the in-app copy. The other ten are stored as a
/// preference and keep English strings until those translations exist.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case mandarin = "zh-Hans"
    case hindi = "hi"
    case arabic = "ar"
    case portuguese = "pt"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case russian = "ru"
    case korean = "ko"
    case indonesian = "id"

    var id: String { rawValue }

    /// Locale used for dates / SwiftUI. Non-translated languages stay on English
    /// so choosing Arabic does not flip the layout to RTL with English words.
    var localeIdentifier: String {
        switch self {
        case .spanish: return "es"
        default: return "en"
        }
    }

    var hasTranslatedCopy: Bool {
        self == .english || self == .spanish
    }

    var label: String {
        switch self {
        case .english: return L10n.settingsLanguageEnglish
        case .spanish: return L10n.settingsLanguageSpanish
        case .mandarin: return L10n.settingsLanguageMandarin
        case .hindi: return L10n.settingsLanguageHindi
        case .arabic: return L10n.settingsLanguageArabic
        case .portuguese: return L10n.settingsLanguagePortuguese
        case .french: return L10n.settingsLanguageFrench
        case .german: return L10n.settingsLanguageGerman
        case .japanese: return L10n.settingsLanguageJapanese
        case .russian: return L10n.settingsLanguageRussian
        case .korean: return L10n.settingsLanguageKorean
        case .indonesian: return L10n.settingsLanguageIndonesian
        }
    }
}

/// Persists language preference per install (and later per signed-in user id).
@MainActor
final class LanguageStore: ObservableObject {
    static let defaultsKey = "atw.language.preference"
    private static let perUserPrefix = "atw.language.user."

    @Published var language: AppLanguage {
        didSet { persist() }
    }

    /// Optional until auth lands — when set, preference is stored per user id.
    var currentUserID: UUID? {
        didSet { reloadForUser() }
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    init() {
        self.language = Self.storedLanguage()
    }

    private func persist() {
        UserDefaults.standard.set(language.rawValue, forKey: Self.defaultsKey)
        if let userID = currentUserID {
            UserDefaults.standard.set(language.rawValue, forKey: Self.perUserPrefix + userID.uuidString)
        }
    }

    private func reloadForUser() {
        guard let userID = currentUserID,
              let raw = UserDefaults.standard.string(forKey: Self.perUserPrefix + userID.uuidString),
              let value = AppLanguage(rawValue: raw) else { return }
        language = value
    }

    private static func storedLanguage() -> AppLanguage {
        let raw = UserDefaults.standard.string(forKey: defaultsKey)
        if let raw, let value = AppLanguage(rawValue: raw) {
            return value
        }
        // Older builds stored "system". Map that to the device language.
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("es") ? .spanish : .english
    }
}
