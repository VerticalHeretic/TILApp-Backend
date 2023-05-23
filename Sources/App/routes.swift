import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.get("api", "acronyms") { req async throws -> [Acronym] in 
        return try await Acronym.query(on: req.db).all()
    }

    app.get("api", "acronyms", ":acronymID") { req async throws -> Acronym in 
        let acronymID: UUID? = req.parameters.get("acronymID")
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }
        return acronym
    }

    app.get("api", "acronyms", "search") { req async throws -> [Acronym] in
        guard let searchTerm = req.query[String.self, at: "term"] else { 
            throw Abort(.badRequest)
        }

        return try await Acronym.query(on: req.db).group(.or) { or in 
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
    }

    app.get("api", "acronyms", "sorted") { req async throws -> [Acronym] in
        return try await Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }
    
    
    app.get("api", "acronyms", "first") { req async throws -> Acronym in
        let acronym = try await Acronym.query(on: req.db).first()
        guard let acronym else { throw Abort(.notFound) } 
        return acronym
    }

    app.post("api", "acronyms") { req async throws -> Acronym in
        let acronym = try req.content.decode(Acronym.self)
        try await acronym.save(on: req.db)

        return acronym
    }

    app.put("api", "acronyms", ":acronymID") { req async throws -> Acronym in
        let acronymID: UUID? = req.parameters.get("acronymID")
        let updatedAcronym = try req.content.decode(Acronym.self)
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) }

        acronym.short = updatedAcronym.short
        acronym.long = updatedAcronym.long

        try await acronym.save(on: req.db)
        return acronym
    }

    app.delete("api", "acronyms", ":acronymID") { req async throws -> HTTPStatus in
        let acronymID: UUID? = req.parameters.get("acronymID")
        let acronym = try await Acronym.find(acronymID, on: req.db)
        guard let acronym else { throw Abort(.notFound) } 

        try await acronym.delete(on: req.db)
        return .noContent
    }
}
