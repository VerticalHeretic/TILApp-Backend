import Vapor
import Fluent
import JWT

struct UserController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.post("register", use: registerHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
        usersRoute.delete(":userID", use: deleteHandler)
        usersRoute.post("siwa", use: signInWithApple)
        usersRoute.get(":userID", "profilePicture", use: getUserProfilePictureHandler)

        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)

        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()

        let tokenAuthGroup = usersRoute.grouped(
            tokenAuthMiddleware,
            guardAuthMiddleware
        )

        tokenAuthGroup.on(
            .POST,
            "profilePicture",
            body: .collect(maxSize: "10mb"),
            use: addProfilePictureHandler
        )
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

    func registerHandler(_ req: Request) async throws -> UserResponse {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)

        do {
            try await user.save(on: req.db)
        } catch {
            throw Abort(.custom(code: 400, reasonPhrase: "There is already a user with such username"))
        }

        return user.buildResponse()
    }

    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let userID: UUID? = req.parameters.get("userID")
        let user = try await User.find(userID, on: req.db)
        guard let user else { throw Abort(.notFound) }

        try await user.delete(on: req.db)
        return .noContent
    }

    func loginHandler(_ req: Request) async throws -> Token {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        return token
    }

    func signInWithApple(_ req: Request) async throws -> Token {
        let data = try req.content.decode(SignInWithAppleToken.self)

        guard let appIdentifier = Environment.get("IOS_APPLICATION_IDENTIFIER") else {
            throw Abort(.internalServerError)
        }

        let appleToken = try await req.jwt.apple.verify(data.token, applicationIdentifier: appIdentifier)
        let user = try await User.query(on: req.db)
                                .filter(\.$siwaIdentifier == appleToken.subject.value)
                                .first()
        if let user {
            let token = try Token.generate(for: user)
            try await token.save(on: req.db)
            return token
        }

        guard let email = appleToken.email,
            let name = data.name
        else {
            throw Abort(.badRequest)
        }

        let newUser = User(
            name: name,
            username: email,
            password: UUID().uuidString,
            siwaIdentifier: appleToken.subject.value,
            email: email
        )

        try await newUser.save(on: req.db)
        let token = try Token.generate(for: newUser)
        try await token.save(on: req.db)
        return token
    }

    func addProfilePictureHandler(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(ImageUploadData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let name = "\(userID)-\(UUID()).jpg"
        let path = req.application.directory.publicDirectory + name
        try await req.fileio.writeFile(.init(data: data.picture), at: path)

        user.profilePicture = name
        try await user.save(on: req.db)

        return .accepted
    }

    func getUserProfilePictureHandler(_ req: Request) async throws -> Response {
        let user = try await User.find(req.parameters.get("userID"), on: req.db)

        guard let user else {
            throw Abort(.notFound, reason: "User with such id not found")
        }

        guard let fileName = user.profilePicture else { throw Abort(.notFound) }
        let path = req.application.directory.publicDirectory + fileName
        return req.fileio.streamFile(at: path)
    }
}

struct ImageUploadData: Content {
    var picture: Data
}
