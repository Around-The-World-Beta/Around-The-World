import Vapor

enum APIValidation {
    static let allowedSkills = Set(SkillLevel.allCases.map(\.rawValue))
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

    static func validateOptionalSkill(_ skill: String?) throws -> String? {
        guard let skill else { return nil }
        let trimmed = skill.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowedSkills.contains(trimmed) else {
            throw Abort(.badRequest, reason: "skillLevel must be one of: \(allowedSkills.sorted().joined(separator: ", "))")
        }
        return trimmed
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
}
