import Fluent

struct CreateAcronym: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Acronym.V20230615.schemaName)
            .id()
            .field(Acronym.V20230615.short, .string, .required)
            .field(Acronym.V20230615.long, .string, .required)
            .field(Acronym.V20230615.userID, .uuid, .required,
                .references(User.V20230615.schemaName, User.V20230615.id)
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Acronym.V20230615.schemaName).delete()
    }
}

extension Acronym {

    enum V20230615 {
        static let schemaName = "Acronyms"

        static let id = FieldKey(stringLiteral: "id")
        static let short = FieldKey(stringLiteral: "short")
        static let long = FieldKey(stringLiteral: "long")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}
