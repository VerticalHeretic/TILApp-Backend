import Fluent

struct CreateCategory: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Category.schema)
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Category.schema).delete()
    }
}
