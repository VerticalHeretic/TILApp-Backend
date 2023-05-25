import XCTVapor
import App

extension Application {
    static func testable() async throws -> Application {
        let app = Application(.testing)
        try await configure(app)

        try await app.autoRevert()
        try await app.autoMigrate()

        return app
    }
}
