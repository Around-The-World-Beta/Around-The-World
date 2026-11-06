import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var session: SessionStore
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section(L10n.settingsAccount) {
                if session.isSignedIn {
                    if let name = session.user?.displayName {
                        LabeledContent(L10n.profileTitle) {
                            Text(name)
                                .foregroundStyle(AppTheme.muted)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                    Button(L10n.authSignOut) {
                        confirmSignOut = true
                    }
                    .foregroundStyle(AppTheme.foreground)
                    .listRowBackground(AppTheme.card)

                    Button(L10n.authDeleteAccount, role: .destructive) {
                        confirmDelete = true
                    }
                    .listRowBackground(AppTheme.card)
                } else {
                    Button(L10n.authSignIn) {
                        session.requestSignIn()
                    }
                    .foregroundStyle(AppTheme.gold)
                    .listRowBackground(AppTheme.card)
                }
            }

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
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .atwScreenBackground()
        .id(languageStore.language)
        .alert(L10n.authSignOut, isPresented: $confirmSignOut) {
            Button(L10n.authSignOut, role: .destructive) {
                Task { await session.signOut() }
            }
            Button(L10n.authCancel, role: .cancel) {}
        } message: {
            Text(L10n.authSignOutConfirm)
        }
        .alert(L10n.authDeleteAccount, isPresented: $confirmDelete) {
            Button(L10n.authDeleteAccount, role: .destructive) {
                Task { await session.deleteAccount() }
            }
            Button(L10n.authCancel, role: .cancel) {}
        } message: {
            Text(L10n.authDeleteConfirm)
        }
        .alert(
            L10n.somethingBroke,
            isPresented: Binding(
                get: { session.lastError != nil && !session.isSignInPresented },
                set: { if !$0 { session.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.lastError = nil }
        } message: {
            Text(session.lastError ?? "")
        }
    }
}
