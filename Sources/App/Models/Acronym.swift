import Vapor
import Fluent

final class Acronym: Model, Content {
    static let schema = Acronym.V20230615.schemaName

    @ID
    var id: UUID?
    @Field(key: Acronym.V20230615.short)
    var short: String
    @Field(key: Acronym.V20230615.long)
    var long: String
    @Parent(key: Acronym.V20230615.userID)
    var user: User
    @Siblings(
        through: AcronymCategoryPivot.self,
        from: \.$acronym,
        to: \.$category)
    var categories: [Category]

    init() {}

    init(
        id: UUID? = nil,
        short: String,
        long: String,
        userID: User.IDValue
    ) {
        self.id = id
        self.short = short
        self.long = long
        self.$user.id = userID
    }
}

extension Acronym {

    func buildResponse(db: Database) async throws -> AcronymResponse {
        return try await .init(
            id: id,
            short: short,
            long: long,
            user: $user.get(on: db).buildResponse(),
            categories: $categories.get(on: db))
    }
}

extension Collection where Element: Acronym {

    func buildResponses(db: Database) async throws -> [AcronymResponse] {
        return try await self.asyncMap { try await $0.buildResponse(db: db) }
    }
}

struct AcronymResponse: Content {
    let id: UUID?
    let short: String
    let long: String
    let user: UserResponse
    let categories: [Category]
}

struct AcronymRequest: Content {
    let short: String
    let long: String
}
