import Fluent

struct CreateAcronymCategoryPivot: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(AcronymCategoryPivot.V20230615.schemaName)
            .id()
            .field(AcronymCategoryPivot.V20230615.acronymID,
                    .uuid,
                    .required,
                    .references(Acronym.V20230615.schemaName, Acronym.V20230615.id, onDelete: .cascade))
            .field(AcronymCategoryPivot.V20230615.categoryID,
                    .uuid,
                    .required,
                    .references("categories", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(AcronymCategoryPivot.V20230615.schemaName).delete()
    }
}

extension AcronymCategoryPivot {

    enum V20230615 {
        static let schemaName = "acronym-category-pivot"

        static let id = FieldKey(stringLiteral: "id")
        static let acronymID = FieldKey(stringLiteral: "acronymID")
        static let categoryID = FieldKey(stringLiteral: "categoryID")
    }
}
