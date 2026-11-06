import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

/// Sign in with Apple — native sheet, not a web wrapper.
struct SignInView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nonceHolder = AppleNonceHolder()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    BrandHeader()
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.authHeadline)
                            .font(AppTheme.displayFont)
                            .italic()
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)
                            .tracking(-0.6)

                        Text(L10n.authSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 36)

                    Spacer(minLength: 24)

                    VStack(spacing: 16) {
                        if AppEnvironment.supabaseURL == nil || AppEnvironment.supabaseAnonKey == nil {
                            Text(L10n.authNotConfigured)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        SignInWithAppleButton(.signIn) { request in
                            let raw = AppleNonce.random()
                            nonceHolder.rawNonce = raw
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = AppleNonce.sha256(raw)
                        } onCompletion: { result in
                            Task { @MainActor in
                                await handle(result)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .disabled(session.isWorking)

                        if session.isWorking {
                            ProgressView()
                                .tint(AppTheme.gold)
                        }

                        if let message = session.lastError {
                            Text(message)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.gold)
                                .multilineTextAlignment(.center)
                        }

                        Text(L10n.authPrivacyNote)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.center)

                        Button {
                            dismiss()
                        } label: {
                            Text(L10n.authKeepBrowsing)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.foreground)
                    }
                    .accessibilityLabel(L10n.authClose)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .atwScreenBackground()
        .onAppear {
            session.lastError = nil
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            session.lastError = error.localizedDescription
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                session.lastError = L10n.authFailed
                return
            }
            guard let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                session.lastError = L10n.authFailed
                return
            }
            guard let rawNonce = nonceHolder.rawNonce else {
                session.lastError = L10n.authFailed
                return
            }
            await session.signInWithApple(
                identityToken: identityToken,
                rawNonce: rawNonce,
                appleUserID: credential.user,
                fullName: credential.fullName
            )
        }
    }
}

/// Sign-in call-to-action used on My Games / Profile when nobody is signed in.
struct SignedOutGateView: View {
    @EnvironmentObject private var session: SessionStore
    var title: String
    var message: String
    var systemImage: String = "person.crop.circle"

    var body: some View {
        VStack(spacing: 16) {
            EmptyStateView(title: title, message: message, systemImage: systemImage)
                .frame(minHeight: 180)

            Button {
                session.requestSignIn()
            } label: {
                Text(L10n.authSignIn.uppercased())
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.primaryForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(ATWPressScaleStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

final class AppleNonceHolder: ObservableObject {
    var rawNonce: String?
}

enum AppleNonce {
    static func random(length: Int = 32) -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return String(bytes.map { alphabet[Int($0) % alphabet.count] })
    }

    static func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    SignInView()
        .environmentObject(SessionStore.shared)
}
