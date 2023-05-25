import Vapor

struct CategoriesController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "categories")
        categoriesRoute.post(use: createHandler)
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
    }

    func createHandler(_ req: Request) async throws -> Category {
        let category = try req.content.decode(Category.self)
        try await category.save(on: req.db)

        return category
    }

    func getAllHandler(_ req: Request) async throws -> [Category] {
        return try await Category.query(on: req.db).all()
    }

    func getHandler(_ req: Request) async throws -> Category {
        let category = try await Category.find(req.parameters.get("categoryID"), on: req.db)
        guard let category else { throw Abort(.notFound) }
        return category
    }
}
