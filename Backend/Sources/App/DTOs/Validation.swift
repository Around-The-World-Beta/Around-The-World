import Vapor

enum APIValidation {
    static let allowedSkills = Set(SkillLevel.allCases.map(\.rawValue))
    /// Design order, not alphabetical — this string is shown to users in error messages.
    static let allowedSkillsLabel = SkillLevel.allCases.map(\.rawValue).joined(separator: ", ")
    static let allowedPositions = Set(FavoritePosition.allCases.map(\.rawValue))
    static let allowedGameStatuses = Set(GameStatus.allCases.map(\.rawValue))
    static let allowedParticipantStatuses = Set(ParticipantStatus.allCases.map(\.rawValue))
    static let allowedFriendshipStatuses = Set(FriendshipStatus.allCases.map(\.rawValue))
    static let allowedFormats: Set<String> = ["5v5", "6v6", "7v7", "8v8", "11v11"]

    static func requireNonEmpty(_ value: String, field: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "\(field) is required")
        }
        return trimmed
    }

    static func validateEmail(_ email: String) throws -> String {
        let normalized = try requireNonEmpty(email, field: "email").lowercased()
        guard normalized.contains("@"), normalized.contains(".") else {
            throw Abort(.badRequest, reason: "email is invalid")
        }
        return normalized
    }

    static func validateDisplayName(_ name: String) throws -> String {
        let trimmed = try requireNonEmpty(name, field: "displayName")
        guard trimmed.count >= 2, trimmed.count <= 60 else {
            throw Abort(.badRequest, reason: "displayName must be between 2 and 60 characters")
        }
        return trimmed
    }

    /// Accepts a canonical tier, or a legacy tier which is rewritten to its canonical
    /// equivalent so older clients keep working without writing stale values.
    static func validateOptionalSkill(_ skill: String?) throws -> String? {
        guard let skill else { return nil }
        let trimmed = skill.trimmingCharacters(in: .whitespacesAndNewlines)
        if let legacy = LegacySkillLevel(rawValue: trimmed) {
            return legacy.canonical.rawValue
        }
        guard allowedSkills.contains(trimmed) else {
            throw Abort(.badRequest, reason: "skillLevel must be one of: \(allowedSkillsLabel)")
        }
        return trimmed
    }

    static func validateOptionalAge(_ age: Int?) throws -> Int? {
        guard let age else { return nil }
        guard (4...99).contains(age) else {
            throw Abort(.badRequest, reason: "age must be between 4 and 99")
        }
        return age
    }

    static func validateSkill(_ skill: String) throws -> String {
        guard let value = try validateOptionalSkill(skill) else {
            throw Abort(.badRequest, reason: "skill is required")
        }
        return value
    }

    static func validateOptionalPosition(_ position: String?) throws -> String? {
        guard let position else { return nil }
        let trimmed = position.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowedPositions.contains(trimmed) else {
            throw Abort(
                .badRequest,
                reason: "favoritePosition must be one of: \(allowedPositions.sorted().joined(separator: ", "))"
            )
        }
        return trimmed
    }

    static func validateFormat(_ format: String) throws -> String {
        let trimmed = try requireNonEmpty(format, field: "format")
        guard allowedFormats.contains(trimmed) else {
            throw Abort(.badRequest, reason: "format must be one of: \(allowedFormats.sorted().joined(separator: ", "))")
        }
        return trimmed
    }

    static func validateGameStatus(_ status: String) throws -> String {
        let trimmed = status.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowedGameStatuses.contains(trimmed) else {
            throw Abort(.badRequest, reason: "status must be one of: \(allowedGameStatuses.sorted().joined(separator: ", "))")
        }
        return trimmed
    }

    static func validateParticipantStatus(_ status: String) throws -> String {
        let trimmed = status.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowedParticipantStatuses.contains(trimmed) else {
            throw Abort(
                .badRequest,
                reason: "status must be one of: \(allowedParticipantStatuses.sorted().joined(separator: ", "))"
            )
        }
        return trimmed
    }

    static func validateFriendshipStatus(_ status: String) throws -> String {
        let trimmed = status.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowedFriendshipStatuses.contains(trimmed) else {
            throw Abort(
                .badRequest,
                reason: "status must be one of: \(allowedFriendshipStatuses.sorted().joined(separator: ", "))"
            )
        }
        return trimmed
    }

    static func validateCapacity(_ capacity: Int) throws {
        guard capacity >= 2, capacity <= 30 else {
            throw Abort(.badRequest, reason: "capacity must be between 2 and 30")
        }
    }

    static func validatePriceCents(_ priceCents: Int) throws {
        guard priceCents >= 0 else {
            throw Abort(.badRequest, reason: "priceCents must be >= 0")
        }
    }

    static func validateCoordinates(latitude: Double, longitude: Double) throws {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw Abort(.badRequest, reason: "latitude/longitude are out of range")
        }
    }

    /// Caps and filters user-written text (bios, host notes, report details).
    enum UserContent {
        static let bioMax = 200
        static let notesMax = 500
        static let cityMax = 100
        static let reportDetailsMax = 500
        static let urlMax = 3

        static func bio(_ value: String?) throws -> String? {
            try optionalText(value, field: "bio", maxLength: bioMax, allowNewlines: true)
        }

        static func notes(_ value: String, required: Bool = false) throws -> String {
            let trimmed = try text(value, field: "notes", maxLength: notesMax, allowNewlines: true)
            if required {
                _ = try APIValidation.requireNonEmpty(trimmed, field: "notes")
            }
            return trimmed
        }

        static func optionalNotes(_ value: String?) throws -> String? {
            try optionalText(value, field: "notes", maxLength: notesMax, allowNewlines: true)
        }

        static func city(_ value: String?) throws -> String? {
            try optionalText(value, field: "city", maxLength: cityMax, allowNewlines: false)
        }

        static func reportDetails(_ value: String?) throws -> String? {
            try optionalText(value, field: "details", maxLength: reportDetailsMax, allowNewlines: true)
        }

        static func optionalText(
            _ value: String?,
            field: String,
            maxLength: Int,
            allowNewlines: Bool
        ) throws -> String? {
            guard let value else { return nil }
            let trimmed = try text(value, field: field, maxLength: maxLength, allowNewlines: allowNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        static func text(
            _ value: String,
            field: String,
            maxLength: Int,
            allowNewlines: Bool
        ) throws -> String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= maxLength else {
                throw Abort(.badRequest, reason: "\(field) must be at most \(maxLength) characters")
            }
            try rejectControlCharacters(trimmed, field: field, allowNewlines: allowNewlines)
            try rejectHTML(trimmed, field: field)
            try rejectExcessURLs(trimmed, field: field)
            return trimmed
        }

        private static func rejectControlCharacters(
            _ value: String,
            field: String,
            allowNewlines: Bool
        ) throws {
            let allowed: Set<Unicode.Scalar> = allowNewlines ? ["\n", "\r", "\t"] : []
            for scalar in value.unicodeScalars {
                if scalar.properties.generalCategory == .control && !allowed.contains(scalar) {
                    throw Abort(.badRequest, reason: "\(field) contains characters that are not allowed")
                }
            }
        }

        private static func rejectHTML(_ value: String, field: String) throws {
            let lowered = value.lowercased()
            let blocked = ["<script", "<iframe", "<object", "<embed", "javascript:"]
            if blocked.contains(where: { lowered.contains($0) }) {
                throw Abort(.badRequest, reason: "\(field) cannot include HTML or scripts")
            }
        }

        private static func rejectExcessURLs(_ value: String, field: String) throws {
            let lowered = value.lowercased()
            let httpCount = lowered.components(separatedBy: "http://").count - 1
            let httpsCount = lowered.components(separatedBy: "https://").count - 1
            let wwwCount = lowered.components(separatedBy: "www.").count - 1
            if httpCount + httpsCount + wwwCount > urlMax {
                throw Abort(.badRequest, reason: "\(field) has too many links")
            }
        }
    }
}
