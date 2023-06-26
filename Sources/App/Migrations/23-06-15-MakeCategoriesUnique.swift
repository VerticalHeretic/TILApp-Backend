import Fluent

struct MakeCategoriesUnique: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Category.V20230615.schemaName)
            .unique(on: Category.V20230615.name)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Category.V20230615.schemaName)
            .deleteUnique(on: Category.V20230615.name)
            .update()
    }
}
