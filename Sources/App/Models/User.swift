import Fluent
import Vapor

final class User: Model, Content {
    static let schema = User.V20230615.schemaName

    @ID
    var id: UUID?
    @Field(key: User.V20230615.name)
    var name: String
    @Field(key: User.V20230615.username)
    var username: String
    @Field(key: User.V20230615.password)
    var password: String
    @Children(for: \.$user)
    var acronyms: [Acronym]
    @OptionalField(key: User.V20230615.siwaIdentifier)
    var siwaIdentifier: String?
    @Field(key: User.V20230615.email)
    var email: String
    @OptionalField(key: User.V20230615.profilePicture)
    var profilePicture: String?
    @OptionalField(key: User.V20230615Twitter.twitterURL)
    var twitterURL: String?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        username: String,
        password: String,
        siwaIdentifier: String? = nil,
        email: String,
        profilePicture: String? = nil,
        twitterURL: String? = nil
    ) {
        self.name = name
        self.username = username
        self.password = password
        self.siwaIdentifier = siwaIdentifier
        self.email = email
        self.profilePicture = profilePicture
        self.twitterURL = twitterURL
    }
}

extension User {

    func buildResponse() -> UserResponse {
        return UserResponse(id: id, name: name, username: username)
    }
}

extension Collection where Element: User {

    func buildResponses() -> [UserResponse] {
        return self.map { $0.buildResponse() }
    }
}

extension User: ModelAuthenticatable {

    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

struct UserResponse: Content {
    var id: UUID?
    var name: String
    var username: String
}
