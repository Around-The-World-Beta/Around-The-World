import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Thin REST client for Supabase Auth. Sign in with Apple is exchanged here;
/// the Vapor API never sees the Apple token — only the resulting access token.
struct SupabaseAuthClient: Sendable {
    var url: URL
    var anonKey: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init?(url: URL?, anonKey: String?, session: URLSession? = nil) {
        guard let url, let anonKey, !anonKey.isEmpty else { return nil }
        self.url = url
        self.anonKey = anonKey
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.waitsForConnectivity = false
            config.timeoutIntervalForRequest = 12
            config.timeoutIntervalForResource = 16
            self.session = URLSession(configuration: config)
        }
        self.decoder = JSONDecoder()
    }

    static func fromEnvironment() -> SupabaseAuthClient? {
        SupabaseAuthClient(url: AppEnvironment.supabaseURL, anonKey: AppEnvironment.supabaseAnonKey)
    }

    func signInWithApple(identityToken: String, rawNonce: String) async throws -> StoredAuthSession {
        let body = AppleIDTokenBody(provider: "apple", idToken: identityToken, nonce: rawNonce)
        return try await tokenRequest(grantType: "id_token", body: body)
    }

    func refresh(refreshToken: String) async throws -> StoredAuthSession {
        let body = RefreshTokenBody(refreshToken: refreshToken)
        return try await tokenRequest(grantType: "refresh_token", body: body)
    }

    func signOut(accessToken: String) async {
        guard let request = try? makeRequest(
            path: "auth/v1/logout",
            method: "POST",
            accessToken: accessToken,
            body: Optional<EmptyJSON>.none
        ) else { return }
        _ = try? await session.data(for: request)
    }

    private func tokenRequest<Body: Encodable>(grantType: String, body: Body) async throws -> StoredAuthSession {
        let request = try makeRequest(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: grantType)],
            accessToken: anonKey,
            body: body
        )
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw SupabaseAuthError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseAuthError.httpStatus(http.statusCode, message: Self.errorMessage(from: data))
        }
        do {
            let payload = try decoder.decode(SupabaseTokenResponse.self, from: data)
            return StoredAuthSession(
                accessToken: payload.accessToken,
                refreshToken: payload.refreshToken,
                expiresAt: Date().addingTimeInterval(TimeInterval(payload.expiresIn)),
                appleUserID: nil
            )
        } catch {
            throw SupabaseAuthError.decoding
        }
    }

    private func makeRequest<Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        accessToken: String,
        body: Body?
    ) throws -> URLRequest {
        var base = url.absoluteString
        if base.hasSuffix("/") { base.removeLast() }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var components = URLComponents(string: "\(base)/\(trimmed)") else {
            throw SupabaseAuthError.invalidResponse
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let endpoint = components.url else {
            throw SupabaseAuthError.invalidResponse
        }
        var request = URLRequest(url: endpoint, timeoutInterval: 12)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private static func errorMessage(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let description = object["error_description"] as? String, !description.isEmpty {
                return description
            }
            if let message = object["msg"] as? String, !message.isEmpty { return message }
            if let message = object["message"] as? String, !message.isEmpty { return message }
            if let error = object["error"] as? String, !error.isEmpty { return error }
        }
        return String(data: data, encoding: .utf8) ?? "Sign in failed."
    }
}

enum SupabaseAuthError: Error, LocalizedError, Sendable {
    case notConfigured
    case invalidResponse
    case decoding
    case transport(String)
    case httpStatus(Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return L10n.authNotConfigured
        case .invalidResponse:
            return L10n.authFailed
        case .decoding:
            return L10n.authFailed
        case .transport(let detail):
            return detail
        case .httpStatus(_, let message):
            return message
        }
    }
}

private struct AppleIDTokenBody: Encodable {
    let provider: String
    let idToken: String
    let nonce: String

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case nonce
    }
}

private struct RefreshTokenBody: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct EmptyJSON: Encodable {}

private struct SupabaseTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
