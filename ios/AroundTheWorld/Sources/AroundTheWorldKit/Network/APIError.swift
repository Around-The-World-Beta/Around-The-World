import Foundation

public enum APIError: Error, Sendable, Equatable, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpStatus(Int, message: String)
    case decoding(String)
    case encoding(String)
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid URL for path: \(path)"
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let code, let message):
            return "HTTP \(code): \(message)"
        case .decoding(let detail):
            return "Failed to decode response: \(detail)"
        case .encoding(let detail):
            return "Failed to encode request: \(detail)"
        case .transport(let detail):
            return "Network transport error: \(detail)"
        }
    }
}
