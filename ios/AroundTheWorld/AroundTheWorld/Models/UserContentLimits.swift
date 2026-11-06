import Foundation

/// Shared caps for user-written text. Must match `APIValidation.UserContent` on the server.
enum UserContentLimits {
    static let bioMax = 200
    static let notesMax = 500
    static let cityMax = 100
    static let reportDetailsMax = 500

    static func clamped(_ value: String, maxLength: Int) -> String {
        String(value.prefix(maxLength))
    }
}
