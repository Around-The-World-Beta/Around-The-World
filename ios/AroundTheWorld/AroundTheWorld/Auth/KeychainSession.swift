import Foundation
import Security

/// Keychain payload for the Supabase Auth session. Tokens live here so they
/// survive app restarts; the app user id does not — that is loaded from `GET /api/v1/me`.
struct StoredAuthSession: Codable, Sendable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var appleUserID: String?
}

enum KeychainSession {
    private static let service = "com.aroundtheworld.app"
    private static let account = "supabase.session"

    static func load() -> StoredAuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(StoredAuthSession.self, from: data)
    }

    static func save(_ session: StoredAuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Refresh lives off `SessionStore` so `NetworkManager` can retry a 401
/// without waiting on the main actor (which may already be awaiting the request).
enum AuthTokenBroker {
    static func refresh() async -> String? {
        guard let stored = KeychainSession.load() else { return nil }
        guard let client = SupabaseAuthClient.fromEnvironment() else { return nil }
        do {
            var session = try await client.refresh(refreshToken: stored.refreshToken)
            session.appleUserID = stored.appleUserID
            KeychainSession.save(session)
            await NetworkManager.shared.setBearerToken(session.accessToken)
            return session.accessToken
        } catch {
            BootLogger.fail("auth.refresh", error)
            return nil
        }
    }
}
