import Fluent
import Vapor

struct CreateAdminUser: AsyncMigration {

    func prepare(on database: Database) async throws {
        let passwordHash: String

        passwordHash = try Bcrypt.hash("password")
        let user = User(
            name: "Admin",
            username: "admin",
            password: passwordHash,
            email: "admin@localhost.local")
        return try await user.save(on: database)
    }

    func revert(on database: Database) async throws {
        try await User.query(on: database)
                    .filter(\.$username == "admin")
                    .delete()
    }
}
