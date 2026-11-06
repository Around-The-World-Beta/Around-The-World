import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWT
import Vapor

public func configure(_ app: Application) async throws {
    if let host = Environment.get("HOST") {
        app.http.server.configuration.hostname = host
    } else if AuthConfiguration.requiresHostedSecrets(for: app.environment) {
        // Railway / Docker must accept traffic from the proxy, not only loopback.
        app.http.server.configuration.hostname = "0.0.0.0"
    }
    if let port = Environment.get("PORT").flatMap(Int.init) {
        app.http.server.configuration.port = port
    } else {
        // Match the iOS client's default (APIConfiguration.iOSSimulatorLocal).
        app.http.server.configuration.port = 8081
    }

    try AuthConfiguration.requireBootConfiguration(for: app.environment)
    try configureDatabase(app)
    try await configureAuth(app)

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateProfiles())
    app.migrations.add(CreateGames())
    app.migrations.add(CreateParticipants())
    app.migrations.add(CreateFriendships())
    app.migrations.add(AddProfileAge())
    app.migrations.add(NormalizeSkillTiers())
    app.migrations.add(EnableRowLevelSecurity())
    app.migrations.add(CreateUserReports())
    app.migrations.add(CreateUserBlocks())
    // Demo Bay Area listings: local/staging only. Never registered in production,
    // even if someone sets SEED_DEMO=1 on the production Railway service.
    let seedRequested = ["1", "true", "yes"].contains((Environment.get("SEED_DEMO") ?? "").lowercased())
    if app.environment == .production {
        if seedRequested {
            app.logger.warning("SEED_DEMO is set but this is production — demo games will not be inserted. Unset SEED_DEMO. Use a staging project if you want demo listings.")
        }
    } else {
        app.migrations.add(SeedDemoData())
    }

    // Idempotent. On a database that already ran docs/supabase-setup.md this is a
    // no-op except SeedDemoData on staging. Required on hosted boots so a fresh
    // DATABASE_URL still gets tables.
    try await app.autoMigrate()

    app.middleware.use(JSONErrorMiddleware())
    app.middleware.use(RateLimitMiddleware())

    let allowedOrigins = AuthConfiguration.allowedCORSOrigins(for: app.environment)
    let cors = CORSMiddleware(
        configuration: .init(
            allowedOrigin: allowedOrigins.isEmpty ? .none : .any(allowedOrigins),
            allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
            allowedHeaders: [
                .accept,
                .authorization,
                .contentType,
                .origin,
                .xRequestedWith,
                .userAgent,
            ]
        )
    )
    app.middleware.use(cors, at: .beginning)

    try routes(app)

    app.logger.info(
        "API ready — health at http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)/health"
    )
}

private func configureAuth(_ app: Application) async throws {
    let secret = try AuthConfiguration.jwtSecret(for: app.environment)
    if secret == AuthConfiguration.developmentJWTSecret {
        app.logger.warning(
            "Using the built-in local JWT secret. Real Sign in with Apple tokens will not verify until SUPABASE_JWT_SECRET is set."
        )
    }
    await app.jwt.keys.add(hmac: HMACKey(from: secret), digestAlgorithm: .sha256)
    if let issuer = AuthConfiguration.expectedIssuer {
        app.logger.info("JWT issuer required: \(issuer)")
    } else if app.environment != .testing {
        app.logger.warning("SUPABASE_URL is not set; token issuer will not be checked")
    }
}

private func configureDatabase(_ app: Application) throws {
    // Prefer hosted/local Postgres when configured; otherwise use SQLite so Mac
    // developers can run the API with zero database setup. Hosted environments
    // already failed the boot check above if DATABASE_URL is missing, so they
    // never fall through to SQLite.
    if let databaseURL = Environment.get("DATABASE_URL"), !databaseURL.isEmpty {
        try configurePostgresURL(app, databaseURL)
        app.logger.info("Using Postgres (DATABASE_URL)")
        return
    }

    let driver = (Environment.get("DATABASE_DRIVER") ?? "sqlite").lowercased()
    if driver == "postgres" || driver == "postgresql" {
        try configureLocalPostgres(app)
        app.logger.info("Using local Postgres")
        return
    }

    let sqlitePath = Environment.get("SQLITE_PATH") ?? "around_the_world.sqlite"
    app.databases.use(.sqlite(.file(sqlitePath)), as: .sqlite)
    app.logger.info("Using SQLite at \(sqlitePath) (set DATABASE_DRIVER=postgres or DATABASE_URL to override)")
}

private func configurePostgresURL(_ app: Application, _ databaseURL: String) throws {
    let tlsMode = (Environment.get("DATABASE_TLS") ?? "require").lowercased()
    var urlString = databaseURL
    if urlString.hasPrefix("postgres://") {
        urlString = "postgresql://" + urlString.dropFirst("postgres://".count)
    }
    guard let url = URL(string: urlString) else {
        throw Abort(.internalServerError, reason: "DATABASE_URL is invalid")
    }
    var config = try SQLPostgresConfiguration(url: url)
    config.coreConfiguration.tls = try postgresTLS(tlsMode)
    app.databases.use(.postgres(configuration: config), as: .psql)
}

private func configureLocalPostgres(_ app: Application) throws {
    let tlsMode = (Environment.get("DATABASE_TLS") ?? "disable").lowercased()
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "atw"
    let password = Environment.get("DATABASE_PASSWORD") ?? "atw_dev_password"
    let database = Environment.get("DATABASE_NAME") ?? "around_the_world"

    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                database: database,
                tls: try postgresTLS(tlsMode)
            )
        ),
        as: .psql
    )
}

private func postgresTLS(_ mode: String) throws -> PostgresConnection.Configuration.TLS {
    switch mode {
    case "disable":
        return .disable
    case "require":
        return .require(try .init(configuration: .clientDefault))
    default:
        return .prefer(try .init(configuration: .clientDefault))
    }
}
