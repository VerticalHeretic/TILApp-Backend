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
        acronymsRoutes.post(use: createHandler)
        acronymsRoutes.put(":acronymID", use: updateHandler)
        acronymsRoutes.delete(":acronymID", use: deleteHandler)
        acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
    }

    func getAllHandler(_ req: Request) async throws -> [Acronym] {
        return try await Acronym.query(on: req.db).all()
    }

    func getHandler(_ req: Request) async throws -> Acronym {
        let acronymID: UUID? = req.parameters.get("acronymID")
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }
        return acronym
    }

    func searchHandler(_ req: Request) async throws -> [Acronym] {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return try await Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
    }

    func sortedHandler(_ req: Request) async throws -> [Acronym] {
        return try await Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }

    func firstHandler(_ req: Request) async throws -> Acronym {
        let acronym = try await Acronym.query(on: req.db).first()
        guard let acronym else { throw Abort(.notFound) }
        return acronym
    }

    func createHandler(_ req: Request) async throws -> Acronym {
        let data = try req.content.decode(CreateAcronymData.self)
        let acronym = Acronym(
            short: data.short,
            long: data.long,
            userID: data.userID
        )

        try await acronym.save(on: req.db)

        return acronym
    }

    func updateHandler(_ req: Request) async throws -> Acronym {
        let acronymID: UUID? = req.parameters.get("acronymID")
        let updatedAcronym = try req.content.decode(CreateAcronymData.self)
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        acronym.short = updatedAcronym.short
        acronym.long = updatedAcronym.long
        acronym.$user.id = updatedAcronym.userID

        try await acronym.save(on: req.db)
        return acronym
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
}
struct CreateAcronymData: Content {
    let short: String
    let long: String
    let userID: UUID
}