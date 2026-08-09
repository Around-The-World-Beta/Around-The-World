import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .spanish: return "es"
        }
    }

    var label: String {
        switch self {
        case .system: return L10n.settingsLanguageSystem
        case .english: return L10n.settingsLanguageEnglish
        case .spanish: return L10n.settingsLanguageSpanish
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
        if let id = language.localeIdentifier {
            return Locale(identifier: id)
        }
        return Locale.autoupdatingCurrent
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.defaultsKey) ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: raw) ?? .system
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
}
