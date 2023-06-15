import Fluent
import Vapor

final class Category: Model, Content {
    static let schema = Category.V20230615.schemaName

    @ID
    var id: UUID?
    @Field(key: Category.V20230615.name)
    var name: String

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
