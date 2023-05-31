import Vapor

struct UserController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.post(use: createHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
        usersRoute.delete(":userID", use: deleteHandler)
    }

    func getAllHandler(_ req: Request) async throws -> [UserResponse] {
        return try await User.query(on: req.db).all().buildResponses()
    }

    func getHandler(_ req: Request) async throws -> UserResponse {
        let id: UUID? = req.parameters.get("userID")
        let user = try await User.find(id, on: req.db)
        guard let user else { throw Abort(.notFound) }

        return user.buildResponse()
    }

    func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
        let id: UUID? = req.parameters.get("userID")
        let user = try await User.find(id, on: req.db)
        guard let user else { throw Abort(.notFound) }

        return try await user.$acronyms.get(on: req.db)
    }

    func createHandler(_ req: Request) async throws -> UserResponse {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)

        try await user.save(on: req.db)

        return user.buildResponse()
    }

    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let userID: UUID? = req.parameters.get("userID")
        let user = try await User.find(userID, on: req.db)
        guard let user else { throw Abort(.notFound) }

        try await user.delete(on: req.db)
        return .noContent
    }
}
