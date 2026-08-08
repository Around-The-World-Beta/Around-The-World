import Foundation

/// Matches Vapor `APIMessage` / `HealthResponse`.
public struct APIMessage: Codable, Sendable, Equatable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public struct HealthResponse: Codable, Sendable, Equatable {
    public let status: String
    public let service: String

    public init(status: String, service: String) {
        self.status = status
        self.service = service
    }
}

/// Matches Vapor `JSONErrorMiddleware.ErrorBody`.
public struct APIErrorBody: Codable, Sendable, Equatable {
    public struct Payload: Codable, Sendable, Equatable {
        public let message: String
        public let status: Int

        public init(message: String, status: Int) {
            self.message = message
            self.status = status
        }
    }

    public let error: Payload

    public init(error: Payload) {
        self.error = error
    }
}
