import Foundation

nonisolated protocol AISessionProviding: Sendable {
    func sessions() async throws -> [AISession]
}

nonisolated struct MockAISessionProvider: AISessionProviding {
    func sessions() async throws -> [AISession] {
        [
            AISession(id: "1", provider: .claude, title: "Fix the login flow", date: Date(), folder: "~/Projects/app", branch: "feature/login", lastPrompt: "Why does the token refresh twice?"),
            AISession(id: "2", provider: .copilot, title: "Add a settings screen", date: Date().addingTimeInterval(-90_000), folder: "~/Projects/app", branch: "main", lastPrompt: "Create the view and the store.")
        ]
    }
}
