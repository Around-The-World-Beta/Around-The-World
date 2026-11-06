import SwiftUI

/// Designed settings list. Sign out and Delete account keep the W2 session calls.
struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var session: SessionStore
    @StateObject private var location = LocationPermissionService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var confirmSignOut = false
    @State private var confirmDelete = false
    @State private var showLanguage = false
    @State private var showNotificationsNote = false
    @State private var showPaymentsNote = false
    @State private var unpublishedLegal: LegalPage?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 8) {
                        SettingsRow(
                            systemImage: "mappin",
                            title: L10n.settingsLocation,
                            subtitle: location.settingsSubtitle
                        ) {
                            location.handleSettingsTap()
                        }

                        SettingsRow(
                            systemImage: "globe",
                            title: L10n.settingsLanguage,
                            subtitle: languageStore.language.label
                        ) {
                            showLanguage = true
                        }

                        SettingsRow(
                            systemImage: "bell",
                            title: L10n.settingsNotifications,
                            subtitle: L10n.settingsNotificationsSoon
                        ) {
                            showNotificationsNote = true
                        }

                        SettingsRow(
                            systemImage: "creditcard",
                            title: L10n.settingsPayments,
                            subtitle: L10n.settingsPaymentsSubtitle
                        ) {
                            showPaymentsNote = true
                        }

                        SettingsRow(
                            systemImage: "questionmark.circle",
                            title: L10n.settingsHelp,
                            subtitle: AppEnvironment.supportURL == nil ? L10n.settingsLegalUnpublished : nil
                        ) {
                            openLegal(.support)
                        }

                        SettingsRow(
                            systemImage: "doc.text",
                            title: L10n.settingsTerms,
                            subtitle: AppEnvironment.termsURL == nil ? L10n.settingsLegalUnpublished : nil
                        ) {
                            openLegal(.terms)
                        }

                        SettingsRow(
                            systemImage: "shield",
                            title: L10n.settingsPrivacy,
                            subtitle: AppEnvironment.privacyPolicyURL == nil ? L10n.settingsLegalUnpublished : nil
                        ) {
                            openLegal(.privacy)
                        }

                        if session.isSignedIn {
                            SettingsRow(
                                systemImage: "rectangle.portrait.and.arrow.right",
                                title: L10n.settingsLogOut
                            ) {
                                confirmSignOut = true
                            }

                            SettingsRow(
                                systemImage: "trash",
                                title: L10n.authDeleteAccount,
                                danger: true
                            ) {
                                confirmDelete = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 96)
                }
            }
        }
        .atwScreenBackground()
        .id(languageStore.language)
        .fullScreenCover(isPresented: $showLanguage) {
            LanguagePickerView()
                .environmentObject(languageStore)
        }
        .alert(L10n.settingsLogOut, isPresented: $confirmSignOut) {
            Button(L10n.settingsLogOut, role: .destructive) {
                Task {
                    await session.signOut()
                    dismiss()
                }
            }
            Button(L10n.authCancel, role: .cancel) {}
        } message: {
            Text(L10n.authSignOutConfirm)
        }
        .alert(L10n.authDeleteAccount, isPresented: $confirmDelete) {
            Button(L10n.authDeleteAccount, role: .destructive) {
                Task {
                    await session.deleteAccount()
                    dismiss()
                }
            }
            Button(L10n.authCancel, role: .cancel) {}
        } message: {
            Text(L10n.authDeleteConfirm)
        }
        .alert(L10n.settingsNotifications, isPresented: $showNotificationsNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.settingsNotificationsSoon)
        }
        .alert(L10n.settingsPayments, isPresented: $showPaymentsNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.settingsPaymentsSubtitle)
        }
        .alert(L10n.settingsLegalMissingTitle, isPresented: Binding(
            get: { unpublishedLegal != nil },
            set: { if !$0 { unpublishedLegal = nil } }
        )) {
            Button("OK", role: .cancel) { unpublishedLegal = nil }
        } message: {
            Text(L10n.settingsLegalMissingMessage)
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

    private func openLegal(_ page: LegalPage) {
        if let url = page.url {
            openURL(url)
        } else {
            unpublishedLegal = page
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            sheetCloseButton { dismiss() }
                .accessibilityLabel(L10n.settingsClose)

            Spacer(minLength: 0)

            Text(L10n.settingsTitle)
                .font(.system(size: 16, weight: .black))
                .textCase(.uppercase)
                .tracking(-0.3)
                .foregroundStyle(AppTheme.foreground)

            Spacer(minLength: 0)

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.card.opacity(0.95))
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }
}

struct LanguagePickerView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    sheetCloseButton { dismiss() }
                        .accessibilityLabel(L10n.settingsClose)
                    Spacer(minLength: 0)
                    Text(L10n.settingsLanguage)
                        .font(.system(size: 16, weight: .black))
                        .textCase(.uppercase)
                        .tracking(-0.3)
                        .foregroundStyle(AppTheme.foreground)
                    Spacer(minLength: 0)
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.card.opacity(0.95))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppTheme.border).frame(height: 1)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AppLanguage.allCases) { option in
                            let active = languageStore.language == option
                            Button {
                                languageStore.language = option
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.label)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.foreground)
                                        if !option.hasTranslatedCopy {
                                            Text(L10n.settingsLanguagePending)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.muted)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    if active {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppTheme.gold)
                                    }
                                }
                                .padding(16)
                                .background(
                                    AppTheme.card,
                                    in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                                        .stroke(active ? AppTheme.gold : AppTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 96)
                }
            }
        }
        .atwScreenBackground()
    }
}

private struct SettingsRow: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var danger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(danger ? AppTheme.destructive : AppTheme.gold)
                    .frame(width: 36, height: 36)
                    .background(
                        AppTheme.secondaryFill.opacity(0.55),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(danger ? AppTheme.destructive : AppTheme.foreground)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(16)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// Public pages Auner publishes, then pastes into Xcode as `PRIVACY_POLICY_URL`,
/// `SUPPORT_URL`, and `TERMS_URL`. Empty on purpose until those links exist —
/// we do not invent a live URL.
enum LegalPage {
    case privacy
    case support
    case terms

    var url: URL? {
        switch self {
        case .privacy: return AppEnvironment.privacyPolicyURL
        case .support: return AppEnvironment.supportURL
        case .terms: return AppEnvironment.termsURL
        }
    }
}
