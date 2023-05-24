import Fluent

struct CreateAcronym: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Acronym.schema)
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Acronym.schema).delete()
    }
}
