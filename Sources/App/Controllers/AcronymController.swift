import Vapor
import Fluent

struct AcronymController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let acronymsRoutes = routes.grouped("api", "acronyms")
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(":acronymID", use: getHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get("first", use: firstHandler)
        acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
        acronymsRoutes.get(":acronymID", "categories", use: getCategoriesHandler)

        // let basicAuthMiddleware = User.authenticator()
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()

        let tokenAuthGroup = acronymsRoutes.grouped(
            tokenAuthMiddleware,
            guardAuthMiddleware
        )

        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":acronymID", use: updateHandler)
        tokenAuthGroup.delete(":acronymID", use: deleteHandler)
        tokenAuthGroup.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
        tokenAuthGroup.delete(":acronymID", "categories", ":categoryID", use: removeCategoriesHandler)
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
}
