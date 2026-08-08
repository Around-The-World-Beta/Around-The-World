import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Reusable async/await HTTP client for the Around The World Vapor API.
///
/// Thread-safe (`actor`). Uses a dedicated `URLSession` with
/// `waitsForConnectivity = false` and short timeouts so a down API cannot
/// freeze the simulator launch path.
public actor NetworkManager {
    public static let shared = NetworkManager()

    private var configuration: APIConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        configuration: APIConfiguration = .localDevelopment,
        session: URLSession? = nil,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil
    ) {
        self.configuration = configuration
        if let session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.waitsForConnectivity = false
            sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
            sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval + 4
            self.session = URLSession(configuration: sessionConfig)
        }
        self.decoder = decoder ?? JSONCoding.decoder
        self.encoder = encoder ?? JSONCoding.encoder
    }

    public func setConfiguration(_ configuration: APIConfiguration) {
        self.configuration = configuration
        BootLogger.step(
            "network.setConfiguration",
            "\(configuration.baseURL.absoluteString) timeout=\(Int(configuration.timeoutInterval))s"
        )
    }

    public func currentConfiguration() -> APIConfiguration {
        configuration
    }

    // MARK: - Generic verbs

    public func get<Response: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await send(method: "GET", path: path, queryItems: queryItems, body: Optional<EmptyBody>.none)
    }

    public func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        try await send(method: "POST", path: path, body: body)
    }

    public func patch<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        try await send(method: "PATCH", path: path, body: body)
    }

    public func delete<Response: Decodable>(_ path: String) async throws -> Response {
        try await send(method: "DELETE", path: path, body: Optional<EmptyBody>.none)
    }

    /// Fire-and-forget style delete when the caller does not need the JSON body.
    public func deleteIgnoringBody(_ path: String) async throws {
        let _: APIMessage = try await delete(path)
    }

    // MARK: - Core

    private struct EmptyBody: Encodable {}

    private func send<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Body?
    ) async throws -> Response {
        let request = try makeRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body
        )

        BootLogger.step("network.request", "\(method) \(request.url?.absoluteString ?? path)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            BootLogger.fail("network.request", error)
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorBody.self, from: data) {
                throw APIError.httpStatus(apiError.error.status, message: apiError.error.message)
            }
            let fallback = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.httpStatus(http.statusCode, message: fallback)
        }

        do {
            let decoded = try decoder.decode(Response.self, from: data)
            BootLogger.done("network.request \(method) \(path) → \(http.statusCode)")
            return decoded
        } catch {
            BootLogger.fail("network.decode", error)
            throw APIError.decoding(String(describing: error))
        }
    }

    private func makeRequest<Body: Encodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        body: Body?
    ) throws -> URLRequest {
        let url = try makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url, timeoutInterval: configuration.timeoutInterval)
        request.httpMethod = method

        for (header, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        if let body {
            do {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw APIError.encoding(String(describing: error))
            }
        }

        return request
    }

    /// Joins `baseURL` + path without percent-encoding `/` segments
    /// (`appendingPathComponent` would turn `api/v1/users` into `api%2Fv1%2Fusers`).
    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var base = configuration.baseURL.absoluteString
        if base.hasSuffix("/") {
            base.removeLast()
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var components = URLComponents(string: "\(base)/\(trimmed)") else {
            throw APIError.invalidURL(path)
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL(path)
        }
        return url
    }
}
