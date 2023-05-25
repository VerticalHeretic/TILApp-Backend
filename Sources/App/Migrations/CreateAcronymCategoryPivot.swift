import Fluent

struct CreateAcronymCategoryPivot: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(AcronymCategoryPivot.schema)
            .id()
            .field("acronymID", .uuid, .required, .references("acronyms", "id", onDelete: .cascade))
            .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(AcronymCategoryPivot.schema).delete()
    }
}
