import Fluent

struct AddTwitterURLToUser: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
                    .field(User.V20230615Twitter.twitterURL, .string)
                    .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema)
                    .deleteField(User.V20230615Twitter.twitterURL)
                    .update()
    }
}