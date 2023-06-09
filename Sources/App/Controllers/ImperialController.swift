import ImperialGoogle
import ImperialGitHub
import Vapor
import Fluent

struct ImperialController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
            fatalError("Google callback URL not set")
        }

        try routes.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: googleCallbackURL,
            scope: ["profile", "email"],
            completion: processGoogleLogin)

        routes.get("iOS", "login-google", use: iOSGoogleLogin)

        guard let githubCallbackURL = Environment.get("GITHUB_CALLBACK_URL") else {
            fatalError("GitHub callback URL not set")
        }

        try routes.oAuth(
            from: GitHub.self,
            authenticate: "login-github",
            callback: githubCallbackURL,
            completion: processGitHubLogin)

         routes.get("iOS", "login-github", use: iOSGitHubLogin)
    }

    func processGoogleLogin(_ req: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        try Google
            .getUser(on: req)
            .flatMap { userInfo in
                User
                    .query(on: req.db)
                    .filter(\.$username == userInfo.email)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            let user = User(
                                name: userInfo.name,
                                username: userInfo.email,
                                password: UUID().uuidString)

                            return user.save(on: req.db).flatMap {
                                // request.session.authenticate(user)
                                return generateRedirect(on: req, for: user)
                            }
                        }

                        // req.session.authenticate(existingUser)
                        return generateRedirect(on: req, for: existingUser)
                    }
            }
    }

    func processGitHubLogin(_ req: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        return try GitHub
            .getUser(on: req)
            .flatMap { userInfo in
                return User
                    .query(on: req.db)
                    .filter(\.$username == userInfo.login)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            let user = User(
                                name: userInfo.name,
                                username: userInfo.login,
                                password: UUID().uuidString)

                            return user
                            .save(on: req.db)
                            .flatMap {
                                return generateRedirect(on: req, for: user)
                            }
                        }
                        return generateRedirect(on: req, for: existingUser)
                    }
            }
    }


    func iOSGitHubLogin(_ req: Request) -> Response {
        req.session.data["oauth_login"] = "iOS"
        return req.redirect(to: "/login-github")
    }

    func iOSGoogleLogin(_ req: Request) -> Response {
        req.session.data["oauth_login"] = "iOS"
        return req.redirect(to: "/login-google")
    }

    func generateRedirect(on req: Request, for user: User) -> EventLoopFuture<ResponseEncodable> {
        let redirectURL: EventLoopFuture<String>
        if req.session.data["oauth_login"] == "iOS" {
            do {
                let token = try Token.generate(for: user)
                redirectURL = token.save(on: req.db).map {
                    "tilapp://auth?token=\(token.value)"
                }
            } catch {
                return req.eventLoop.future(error: error)
            }
        } else {
            redirectURL = req.eventLoop.future("/")
        }

        req.session.data["oauth_login"] = nil
        return redirectURL.map { url in
            req.redirect(to: url)
        }
    }
}
