import Fluent

struct CreateCategory: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Category.V20230615.schemaName)
            .id()
            .field(Category.V20230615.name, .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Category.V20230615.schemaName).delete()
    }
}

extension Category {

    enum V20230615 {
        static let schemaName = "categories"

        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
    }
}
