import Vapor

final class LogMiddleware: AsyncMiddleware {

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let start = Date()

        let response = try await next.respond(to: request)
        self.log(response, start: start, for: request)
        return response
    }

    func log(_ res: Response, start: Date, for req: Request) {
        let reqInfo = "\(req.method.string) \(req.url.path)"
        let resInfo = "\(res.status.code) " +  "\(res.status.reasonPhrase)"
        let time = Date()
            .timeIntervalSince(start)
            .readableMilliseconds

        req.logger.info("\(reqInfo) -> \(resInfo) [\(time)]")
    }
}

extension TimeInterval {
  /// Converts the time internal to readable milliseconds format, i.e., "3.4ms"
  var readableMilliseconds: String {
    let string = (self * 1000).description
    // include one decimal point after the zero
    let endIndex = string.index(string.firstIndex(of: ".")!, offsetBy: 2)
    let trimmed = string[string.startIndex..<endIndex]
    return .init(trimmed) + "ms"
  }
}