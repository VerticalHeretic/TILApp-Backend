import Vapor
import ImperialGoogle

struct GoogleUserInfo: Content {
    let email: String
    let name: String
}

extension Google {

    static func getUser(on req: Request) async throws -> GoogleUserInfo {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: req.accessToken())

        let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"

        let response = try await req
            .client
            .get(googleAPIURL, headers: headers)

        guard response.status == .ok else {
            if response.status == .unauthorized {
                throw Abort.redirect(to: "/login-google")
            } else {
                throw Abort(.internalServerError)
            }
        }

        return try response.content.decode(GoogleUserInfo.self)
    }

    static func getUser(on request: Request) throws -> EventLoopFuture<GoogleUserInfo> {
      var headers = HTTPHeaders()
      headers.bearerAuthorization =
        try BearerAuthorization(token: request.accessToken())

      let googleAPIURL: URI =
        "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"

      return request
        .client
        .get(googleAPIURL, headers: headers)
        .flatMapThrowing { response in
            guard response.status == .ok else {
                if response.status == .unauthorized {
                    throw Abort.redirect(to: "/login-google")
                } else {
                    throw Abort(.internalServerError)
                }
            }

        return try response.content
          .decode(GoogleUserInfo.self)
      }
  }
}
