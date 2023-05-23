import Vapor
import Fluent

final class Acronym: Model { 
    static let schema = "acronyms" // This model table name in database

    @ID
    var id: UUID?
    @Field(key: "short")    
    var short: String
    @Field(key: "long")
    var long: String

    init() {}

    init(id: UUID? = nil, short: String, long: String) { 
        self.id = id
        self.short = short
        self.long = long 
    }
}

extension Acronym: Content {}