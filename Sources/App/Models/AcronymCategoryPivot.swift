import Fluent
import Foundation

final class AcronymCategoryPivot: Model {
    static let schema = "acronym-category-pivot"

    @ID
    var id: UUID?
    @Parent(key: AcronymCategoryPivot.V20230615.acronymID)
    var acronym: Acronym
    @Parent(key: AcronymCategoryPivot.V20230615.categoryID)
    var category: Category

    init() {}

    init(
        id: UUID? = nil,
        acronym: Acronym,
        category: Category
    ) throws {
        self.id = id
        self.$acronym.id = try acronym.requireID()
        self.$category.id = try category.requireID()
    }
}
