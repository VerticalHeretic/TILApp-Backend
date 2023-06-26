import Fluent
import Vapor

func routes(_ app: Application) throws {

    let acronymController = AcronymController()
    let userController = UserController()
    let categoriesController = CategoriesController()
    let imperialController = ImperialController()
    let openAPIController = OpenAPIController()

    try app.register(collection: acronymController)
    try app.register(collection: userController)
    try app.register(collection: categoriesController)
    try app.register(collection: imperialController)
    try app.register(collection: openAPIController)
}
