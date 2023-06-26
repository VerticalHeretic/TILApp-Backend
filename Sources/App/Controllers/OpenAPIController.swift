import Vapor
import VaporToOpenAPI

struct OpenAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
     	// generate OpenAPI documentation
		routes.get("swagger", "swagger.json") { req in
			req.application.routes.openAPI(
				info: InfoObject(
					title: "TILApp - OpenAPI",
					description: "This is a Acronyms API server's swagger documentation, feel free to use it 🚀",
					contact: ContactObject(
						email: "lukasz.marek.stachnik@gmail.com"
					),
					version: Version(0, 0, 1)
				),
				externalDocs: ExternalDocumentationObject(
					description: "Find out more about Swagger",
					url: URL(string: "http://swagger.io")!
				)
			)
		}
		.excludeFromOpenAPI()
    }
}
