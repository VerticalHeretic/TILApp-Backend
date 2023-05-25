import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "It works!"
    }

    app.get("hello") { _ async -> String in
        "Hello, world!"
    }

    let acronymController = AcronymController()
    let userController = UserController()
    let categoriesController = CategoriesController()

    try app.register(collection: acronymController)
    try app.register(collection: userController)
    try app.register(collection: categoriesController)
}
