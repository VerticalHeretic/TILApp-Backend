import Fluent

struct CreateUser: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(User.V20230615.schemaName)
            .id()
            .field(User.V20230615.name, .string, .required)
            .field(User.V20230615.username, .string, .required)
            .field(User.V20230615.password, .string, .required)
            .field(User.V20230615.siwaIdentifier, .string)
            .field(User.V20230615.email, .string, .required)
            .field(User.V20230615.profilePicture, .string)
            .unique(on: User.V20230615.username, User.V20230615.email)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.V20230615.schemaName).delete()
    }
}

extension User {

    enum V20230615 {
        static let schemaName = "users"

        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let password = FieldKey(stringLiteral: "password")
        static let siwaIdentifier = FieldKey(stringLiteral: "siwaIdentifier")
        static let email = FieldKey(stringLiteral: "email")
        static let profilePicture = FieldKey(stringLiteral: "profilePicture")
        static let username = FieldKey(stringLiteral: "username")
    }

    enum V20230615Twitter {
        static let twitterURL = FieldKey(stringLiteral: "twitterURL")
    }
}
