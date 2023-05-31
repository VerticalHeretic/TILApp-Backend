import Fluent

struct CreateToken: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Token.schema)
                    .id()
                    .field("value", .string, .required)
                    .field("userID", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                    .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Token.schema).delete()
    }
}
