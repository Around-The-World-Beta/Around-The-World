import Foundation

/// Base URL and header configuration for talking to the Vapor server.
public struct APIConfiguration: Sendable, Equatable {
    public var baseURL: URL
    public var defaultHeaders: [String: String]
    public var timeoutInterval: TimeInterval

    public init(
        baseURL: URL,
        defaultHeaders: [String: String] = ["Accept": "application/json"],
        timeoutInterval: TimeInterval = 8
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
    }

    /// Local Vapor default used during Phase 1 smoke tests.
    public static let localDevelopment = APIConfiguration(
        baseURL: URL(string: "http://127.0.0.1:8081")!,
        timeoutInterval: 8
    )

    /// Simulator-friendly alias for the Mac host when the API runs on the development machine.
    public static let iOSSimulatorLocal = APIConfiguration(
        baseURL: URL(string: "http://127.0.0.1:8081")!,
        timeoutInterval: 8
    )
}
