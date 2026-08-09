import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.settingsLanguage) {
                    ForEach(AppLanguage.allCases) { option in
                        Button {
                            languageStore.language = option
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundStyle(AppTheme.foreground)
                                Spacer()
                                if languageStore.language == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.gold)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }

                Section(L10n.settingsAPIKeys) {
                    let missing = AppEnvironment.missingKeys
                    if missing.isEmpty {
                        Text(L10n.settingsKeysOK)
                            .foregroundStyle(AppTheme.muted)
                            .listRowBackground(AppTheme.card)
                    } else {
                        Text(L10n.settingsMissingKeys(missing.joined(separator: ", ")))
                            .foregroundStyle(AppTheme.muted)
                            .listRowBackground(AppTheme.card)
                    }

                    LabeledContent("API_BASE_URL") {
                        Text(AppEnvironment.apiBaseURL.absoluteString)
                            .font(.caption.monospaced())
                            .foregroundStyle(AppTheme.muted)
                    }
                    .listRowBackground(AppTheme.card)
                }

                Section("Brand") {
                    Text(L10n.logoPending)
                        .foregroundStyle(AppTheme.muted)
                        .listRowBackground(AppTheme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .atwScreenBackground()
        // Force view refresh when language changes so L10n picks up new bundle.
        .id(languageStore.language)
    }
}
