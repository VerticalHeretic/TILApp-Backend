import Vapor
import Fluent

final class Acronym: Model, Content {
    static let schema = "acronyms" // This model table name in database

    @ID
    var id: UUID?
    @Field(key: "short")
    var short: String
    @Field(key: "long")
    var long: String
    @Parent(key: "userID")
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
