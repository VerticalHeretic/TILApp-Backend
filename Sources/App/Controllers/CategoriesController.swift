import Vapor

struct CategoriesController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let categoriesRoutes = buildGeneralCategoriesRoutes(routes: routes)
        buildAuthenticatedCategoryRoutes(routes: categoriesRoutes)
    }

    func createHandler(_ req: Request) async throws -> Category {
        let category = try req.content.decode(Category.self)

        do {
            try await category.save(on: req.db)
        } catch {
            throw Abort(.notAcceptable, reason: "Category already exists")
        }

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

    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let categoryID: UUID? = req.parameters.get("categoryID")
        let category = try await Category.find(categoryID, on: req.db)
        guard let category else { throw Abort(.notFound) }

        try await category.delete(on: req.db)
        return .noContent
    }

    private func buildGeneralCategoriesRoutes(routes: RoutesBuilder) -> RoutesBuilder {
        let categoriesRoutes = routes
            .groupedOpenAPI(tags: ["Categories"])
            .grouped("api", "categories")

        categoriesRoutes.get(use: getAllHandler)
                .openAPI(
                    summary: "Get all categories",
                    response: .type([Category].self)
                )
        categoriesRoutes.get(":categoryID", use: getHandler)
                .openAPI(
                    summary: "Get category by ID",
                    response: .type(Category.self)
                )
        return categoriesRoutes
    }

    private func buildAuthenticatedCategoryRoutes(routes: RoutesBuilder)  {
        let categoriesRoutes = buildGeneralCategoriesRoutes(routes: routes)

        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()

        let tokenAuthGroup = categoriesRoutes.grouped(
            tokenAuthMiddleware,
            guardAuthMiddleware
        )

        tokenAuthGroup.post(use: createHandler)
                .openAPI(
                    summary: "Create an category",
                    body: .type(Category.self),
                    response: .type(Category.self)
                )
        tokenAuthGroup.delete(":categoryID", use: deleteHandler)
                .openAPI(
                    summary: "Delete category with ID",
                    response: .type(HTTPStatus.self)
                )
    }
}
