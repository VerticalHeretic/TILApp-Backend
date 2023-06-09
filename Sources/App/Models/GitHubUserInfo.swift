import Vapor
import ImperialGitHub

struct GitHubUserInfo: Content {
    let name: String
    let login: String
}

extension GitHub {
    static func getUser(on request: Request) throws -> EventLoopFuture<GitHubUserInfo> {
        var headers = HTTPHeaders()
        try headers.add(name: .authorization, value: "token \(request.accessToken())")
        headers.add(name: .userAgent, value: "vapor")

        let githubAPIURL: URI = "https://api.github.com/user"

        return request
            .client
            .get(githubAPIURL, headers: headers)
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    if response.status == .unauthorized {
                        throw Abort.redirect(to: "/login-github")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }

                return try response.content
                    .decode(GitHubUserInfo.self)
            }
    }
}
