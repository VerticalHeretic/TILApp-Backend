import NIOSSL
import Fluent
import FluentPostgresDriver
import SendGrid
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)

    let databaseName: String
    let databasePort: Int

    if app.environment == .testing {
        databaseName = "vapor_test_database"
        databasePort = 5433
    } else {
       databaseName = "vapor_database"
        databasePort = 5432
    }

    app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? databasePort,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? databaseName,
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateAcronymCategoryPivot())
    app.migrations.add(CreateToken())
    app.migrations.add(AddTwitterURLToUser())

    switch app.environment {
    case .development, .testing:
        app.migrations.add(CreateAdminUser())
    default:
        break
    }

    app.migrations.add(MakeCategoriesUnique())

    app.logger.logLevel = .debug

    try await app.autoMigrate()

    try routes(app)
    app.sendgrid.initialize()
}
