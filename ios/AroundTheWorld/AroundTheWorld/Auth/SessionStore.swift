import AuthenticationServices
import Foundation
import SwiftUI

/// Process-wide signed-in user. Screens read `isSignedIn` / `user` / `profile`.
/// The access token stays in the Keychain and on `NetworkManager`; `user.id` is
/// not a credential and is never sent back to prove identity.
@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var user: UserResponse?
    @Published private(set) var profile: ProfileResponse?
    @Published private(set) var isRestoring = true
    @Published private(set) var isWorking = false
    @Published private(set) var hasSession = false
    @Published var isSignInPresented = false
    @Published var lastError: String?

    /// True when a Keychain session exists. Browse still works when this is false.
    var isSignedIn: Bool { hasSession }

    /// App user id for local UI only (language preference, profile header).
    var userID: UUID? { user?.id }

    private var storedSession: StoredAuthSession?
    private let api = AroundTheWorldAPI()
    private let refreshLeeway: TimeInterval = 60

    private init() {}

    func requestSignIn() {
        isSignInPresented = true
    }

    func restoreIfNeeded() async {
        isRestoring = true
        defer { isRestoring = false }

        guard let stored = KeychainSession.load() else {
            await applyLocalSession(nil)
            BootLogger.done("2/4 auth — signed out")
            return
        }

        if let appleUserID = stored.appleUserID {
            do {
                let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: appleUserID)
                if state == .revoked || state == .notFound {
                    BootLogger.step("2/4 auth", "Apple credential revoked — signing out")
                    await signOut()
                    return
                }
            } catch {
                BootLogger.fail("2/4 apple.credentialState", error)
            }
        }

        storedSession = stored
        hasSession = true
        await NetworkManager.shared.setBearerToken(stored.accessToken)
        await NetworkManager.shared.setRefreshHandler { await AuthTokenBroker.refresh() }

        if stored.expiresAt.timeIntervalSinceNow < refreshLeeway {
            if await refreshAccessToken() == nil {
                BootLogger.step("2/4 auth", "refresh failed on restore")
            }
        }

        await loadCurrentUser(allowTransportFailure: true)
        BootLogger.done("2/4 auth — \(user == nil ? "session present, profile pending" : "signed in")")
    }

    func signInWithApple(
        identityToken: String,
        rawNonce: String,
        appleUserID: String,
        fullName: PersonNameComponents?
    ) async {
        lastError = nil
        isWorking = true
        defer { isWorking = false }

        guard let client = SupabaseAuthClient.fromEnvironment() else {
            lastError = L10n.authNotConfigured
            return
        }

        do {
            var session = try await client.signInWithApple(identityToken: identityToken, rawNonce: rawNonce)
            session.appleUserID = appleUserID
            await install(session)
            if let fullName {
                await applyAppleDisplayName(fullName)
            }
            isSignInPresented = false
        } catch {
            lastError = error.localizedDescription
            BootLogger.fail("auth.apple", error)
        }
    }

    func signOut() async {
        let access = storedSession?.accessToken
        if let access, let client = SupabaseAuthClient.fromEnvironment() {
            await client.signOut(accessToken: access)
        }
        await applyLocalSession(nil)
        lastError = nil
        BootLogger.done("auth.signOut")
    }

    func deleteAccount() async {
        lastError = nil
        isWorking = true
        defer { isWorking = false }

        guard isSignedIn else {
            lastError = L10n.authSignInRequired
            return
        }

        do {
            _ = try await api.deleteCurrentUser()
            await signOut()
        } catch {
            lastError = error.localizedDescription
            BootLogger.fail("auth.deleteAccount", error)
        }
    }

    /// Returns a fresh access token or nil. Reads the refresh token from Keychain.
    func refreshAccessToken() async -> String? {
        guard let token = await AuthTokenBroker.refresh() else {
            await applyLocalSession(nil)
            return nil
        }
        storedSession = KeychainSession.load()
        hasSession = storedSession != nil
        return token
    }

    func reloadProfile() async {
        guard storedSession != nil else { return }
        await loadCurrentUser(allowTransportFailure: true)
    }

    private func install(_ session: StoredAuthSession) async {
        storedSession = session
        hasSession = true
        KeychainSession.save(session)
        await NetworkManager.shared.setBearerToken(session.accessToken)
        await NetworkManager.shared.setRefreshHandler { await AuthTokenBroker.refresh() }
        // Keep the Apple/Supabase session even if `/me` is not on the server yet (W1).
        await loadCurrentUser(allowTransportFailure: true)
    }

    private func loadCurrentUser(allowTransportFailure: Bool) async {
        do {
            let me = try await api.currentUser()
            user = me.user
            profile = me.profile
            lastError = nil
        } catch let error as APIError {
            user = nil
            profile = nil
            if case .httpStatus(401, _) = error {
                await applyLocalSession(nil)
                return
            }
            if allowTransportFailure {
                lastError = nil
                BootLogger.fail("auth.me (kept session)", error)
                return
            }
            lastError = error.localizedDescription
            BootLogger.fail("auth.me", error)
        } catch {
            if allowTransportFailure {
                BootLogger.fail("auth.me (kept session)", error)
                return
            }
            lastError = error.localizedDescription
            BootLogger.fail("auth.me", error)
        }
    }

    private func applyAppleDisplayName(_ name: PersonNameComponents) async {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let display = formatter.string(from: name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !display.isEmpty else { return }
        do {
            let me = try await api.updateCurrentUser(UpdateMeRequest(displayName: display))
            user = me.user
            profile = me.profile
        } catch {
            BootLogger.fail("auth.displayName", error)
        }
    }

    private func applyLocalSession(_ session: StoredAuthSession?) async {
        storedSession = session
        hasSession = session != nil
        if let session {
            KeychainSession.save(session)
            await NetworkManager.shared.setBearerToken(session.accessToken)
        } else {
            KeychainSession.clear()
            await NetworkManager.shared.setBearerToken(nil)
            await NetworkManager.shared.setRefreshHandler(nil)
            user = nil
            profile = nil
        }
    }
}
