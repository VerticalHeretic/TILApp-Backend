import Vapor
import Fluent
import VaporToOpenAPI

struct AcronymController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let acronymRoutes = buildGeneralAcronymRoutes(routes: routes)
        buildAuthenticatedAcronymRoutes(builder: acronymRoutes)
    }

    func getAllHandler(_ req: Request) async throws -> [AcronymResponse] {
        let acronyms = try await Acronym.query(on: req.db).with(\.$categories).with(\.$user).all()

        return try await acronyms.buildResponses(db: req.db)
    }

    func getHandler(_ req: Request) async throws -> AcronymResponse {
        let acronymID: UUID? = req.parameters.get("acronymID")
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        return try await acronym.buildResponse(db: req.db)
    }

    func searchHandler(_ req: Request) async throws -> [AcronymResponse] {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        let acronyms = try await Acronym.query(on: req.db)
            .with(\.$categories)
            .with(\.$user)
            .group(.or) { or in
                or.filter(\.$short == searchTerm)
                or.filter(\.$long == searchTerm)
            }
            .all()

        return try await acronyms.buildResponses(db: req.db)
    }

    func sortedHandler(_ req: Request) async throws -> [AcronymResponse] {
       let acronyms = try await Acronym.query(on: req.db)
            .with(\.$categories)
            .with(\.$user)
            .sort(\.$short, .ascending)
            .all()

        return try await acronyms.buildResponses(db: req.db)
    }

    func firstHandler(_ req: Request) async throws -> AcronymResponse {
        let acronym = try await Acronym.query(on: req.db)
            .with(\.$categories)
            .with(\.$user)
            .first()
        guard let acronym else { throw Abort(.notFound) }

        return try await acronym.buildResponse(db: req.db)
    }

    func createHandler(_ req: Request) async throws -> AcronymResponse {
        let data = try req.content.decode(AcronymRequest.self)
        let user = try req.auth.require(User.self)

        let acronym = try Acronym(
            short: data.short,
            long: data.long,
            userID: user.requireID()
        )

        try await acronym.save(on: req.db)
        return try await acronym.buildResponse(db: req.db)
    }

    func updateHandler(_ req: Request) async throws -> AcronymResponse {
        let acronymID: UUID? = req.parameters.get("acronymID")
        let updatedAcronym = try req.content.decode(AcronymRequest.self)
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }
        let user = try req.auth.require(User.self)

        acronym.short = updatedAcronym.short
        acronym.long = updatedAcronym.long
        acronym.$user.id = try user.requireID()

        try await acronym.save(on: req.db)
        return try await acronym.buildResponse(db: req.db)
    }

    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let acronymID: UUID? = req.parameters.get("acronymID")
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        try await acronym.delete(on: req.db)
        return .noContent
    }

    func getUserHandler(_ req: Request) async throws -> User {
        let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        return try await acronym.$user.get(on: req.db)
    }

    func addCategoriesHandler(_ req: Request) async throws -> HTTPStatus {
        let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        let category = try await Category.find(req.parameters.get("categoryID"), on: req.db)
        guard let category else { throw Abort(.notFound) }

        let acronymCategories = try await acronym.$categories.query(on: req.db).all()

        guard !acronymCategories.contains(where: { $0.id == category.id }) else { throw Abort(.notAcceptable) }

        try await acronym.$categories.attach(category, on: req.db)
        return .created
    }

    func getCategoriesHandler(_ req: Request) async throws -> [Category] {
        let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        return try await acronym.$categories.query(on: req.db).all()
    }

    func removeCategoriesHandler(_ req: Request) async throws -> HTTPStatus {
        let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        let category = try await Category.find(req.parameters.get("categoryID"), on: req.db)
        guard let category else { throw Abort(.notFound) }

        let acronymCategories = try await acronym.$categories.query(on: req.db).all()

        guard acronymCategories.contains(where: { $0.id == category.id }) else { throw Abort(.notAcceptable) }

        try await acronym.$categories.detach(category, on: req.db)
        return .noContent
    }

    private func buildGeneralAcronymRoutes(routes: RoutesBuilder) -> RoutesBuilder {
        let acronymsRoutes = routes
            .groupedOpenAPI(tags: ["Acronyms"])
            .grouped("api", "acronyms")

            acronymsRoutes.get(use: getAllHandler)
                .openAPI(
                    summary: "Get all acronyms",
                    response: .type([AcronymResponse].self)
                )
            acronymsRoutes.get(":acronymID", use: getHandler)
                .openAPI(
                    summary: "Get acornym by ID",
                    response: .type(AcronymResponse.self)
                )
            acronymsRoutes.get("search", use: searchHandler)
                .openAPI(
                    summary: "Search acronyms",
                    response: .type([AcronymResponse].self)
                )
            acronymsRoutes.get("sorted", use: sortedHandler)
                .openAPI(
                    summary: "Get sorted acronyms",
                    response: .type([AcronymResponse].self)
                )
            acronymsRoutes.get("first", use: firstHandler)
                .openAPI(
                    summary: "Get first acronym",
                    response: .type(AcronymResponse.self)
                )
            acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
                .openAPI(
                    summary: "Get user of acronym with ID",
                    response: .type(UserResponse.self)
                )
            acronymsRoutes.get(":acronymID", "categories", use: getCategoriesHandler)
                .openAPI(
                    summary: "Get categories of acronym with ID",
                    response: .type([Category].self)
                )
        return acronymsRoutes
    }

    private func buildAuthenticatedAcronymRoutes(builder: RoutesBuilder) {
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()

        let tokenAuthGroup = builder
            .groupedOpenAPI(auth: .bearer(id: "Authorization"))
            .groupedOpenAPIResponse(statusCode: .unauthorized)
            .grouped(
                tokenAuthMiddleware,
                guardAuthMiddleware
            )

        tokenAuthGroup.post(use: createHandler)
            .openAPI(
                summary: "Create an acronym",
                description: "Create an acronym with provided data",
                body: .type(AcronymRequest.self),
                response: .type(AcronymResponse.self)
            )

        tokenAuthGroup.put(":acronymID", use: updateHandler)
            .openAPI(
                summary: "Update an acronym",
                description: "Updates an acronym with provided data",
                body: .type(AcronymRequest.self),
                response: .type(AcronymResponse.self)
            )
        tokenAuthGroup.delete(":acronymID", use: deleteHandler)
            .openAPI(
                summary: "Delete an acronym",
                description: "Deletes an acronym with provided ID",
                response: .type(HTTPStatus.self)
            )
        tokenAuthGroup.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
            .openAPI(
                summary: "Add category to acronym",
                description: "Add category to acronym with provided ID of acronym and category",
                response: .type(HTTPStatus.self)
            )
        tokenAuthGroup.delete(":acronymID", "categories", ":categoryID", use: removeCategoriesHandler)
            .openAPI(
                summary: "Remove category from acronym",
                description: "Remove category from acronym with provided ID of acronym and category",
                response: .type(HTTPStatus.self)
            )
    }
}
