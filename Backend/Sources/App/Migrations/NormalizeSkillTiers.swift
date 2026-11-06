import Fluent

/// Rewrites skill tiers persisted before the canonical list was settled.
///
/// `games.skill` and `profiles.skill_level` were written as "Beginner" by earlier seeds
/// and clients. The canonical tier is "Casual" (`SkillLevel`), so any existing database —
/// local SQLite, staging, or production Postgres — is brought in line here rather than
/// left for the API to paper over on read.
struct NormalizeSkillTiers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        for legacy in LegacySkillLevel.allCases {
            try await Game.query(on: database)
                .filter(\.$skill == legacy.rawValue)
                .set(\.$skill, to: legacy.canonical.rawValue)
                .update()

            try await Profile.query(on: database)
                .filter(\.$skillLevel == legacy.rawValue)
                .set(\.$skillLevel, to: legacy.canonical.rawValue)
                .update()
        }
    }

    /// Not invertible: rows legitimately created as "Casual" are indistinguishable from
    /// rows migrated from "Beginner", so reverting would corrupt the former. Reverting
    /// is a no-op, and the API still accepts the legacy spelling on input either way.
    func revert(on database: any Database) async throws {}
}
