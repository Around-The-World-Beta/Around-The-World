import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    if let host = Environment.get("HOST") {
        app.http.server.configuration.hostname = host
    }
    if let port = Environment.get("PORT").flatMap(Int.init) {
        app.http.server.configuration.port = port
    }

    try configureDatabase(app)

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateProfiles())
    app.migrations.add(CreateGames())
    app.migrations.add(CreateParticipants())
    app.migrations.add(CreateFriendships())

    // Auto-migrate in development so local smoke tests work without a separate migrate step.
    // Staging/production should run `swift run App migrate` explicitly (see Backend/README.md).
    if app.environment == .development {
        try await app.autoMigrate()
    }

    app.middleware.use(JSONErrorMiddleware())

    let corsOrigin = Environment.get("CORS_ORIGIN") ?? "*"
    let cors = CORSMiddleware(
        configuration: .init(
            allowedOrigin: corsOrigin == "*" ? .all : .originBased,
            allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
            allowedHeaders: [
                .accept,
                .authorization,
                .contentType,
                .origin,
                .xRequestedWith,
                .userAgent,
                .accessControlAllowOrigin,
            ]
        )
    )
    app.middleware.use(cors, at: .beginning)

    try routes(app)
}

private func configureDatabase(_ app: Application) throws {
    let tlsMode = (Environment.get("DATABASE_TLS") ?? "prefer").lowercased()

    if let databaseURL = Environment.get("DATABASE_URL") {
        var urlString = databaseURL
        // Supabase often provides postgres:// — normalize for URL parsing.
        if urlString.hasPrefix("postgres://") {
            urlString = "postgresql://" + urlString.dropFirst("postgres://".count)
        }
        guard let url = URL(string: urlString) else {
            throw Abort(.internalServerError, reason: "DATABASE_URL is invalid")
        }
        var config = try SQLPostgresConfiguration(url: url)
        config.coreConfiguration.tls = try postgresTLS(tlsMode)
        app.databases.use(.postgres(configuration: config), as: .psql)
        return
    }

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
