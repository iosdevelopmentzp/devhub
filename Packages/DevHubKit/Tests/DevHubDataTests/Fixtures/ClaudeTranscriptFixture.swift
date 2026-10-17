enum ClaudeTranscriptFixture {
    static let summary = #"{"type":"summary","summary":"Ignored","cwd":"/ignored"}"#
    static let user = #"{"type":"user","cwd":"/Users/me/Projects/App","gitBranch":"feature/x","timestamp":"2026-01-02T03:04:05.000Z","message":{"role":"user"}}"#
    static let secondUser = #"{"type":"user","cwd":"/Users/me/Other","gitBranch":"other","timestamp":"2026-01-03T00:00:00.000Z"}"#
    static let aiTitle = #"{"type":"ai-title","aiTitle":"AI title"}"#
    static let customTitle = #"{"type":"custom-title","customTitle":"Custom title"}"#
    static let lastPrompt = #"{"type":"last-prompt","lastPrompt":"Fix the\nbug  "}"#
    static let detachedUser = #"{"type":"user","cwd":"/Users/me/Projects/App","gitBranch":"HEAD"}"#
    static let emptyBranchAttachment = #"{"type":"attachment","cwd":"/Users/me/Projects/App","gitBranch":""}"#
    static let untypedLine = #"{"parentUuid":null,"cwd":"/Users/me/Untyped","gitBranch":"main"}"#
    static let userWithoutCwd = #"{"type":"user","message":{"role":"user"}}"#
    static let assistant = #"{"type":"assistant","cwd":"/Users/me/Assistant"}"#

    static func lastPrompt(_ text: String) -> String {
        #"{"type":"last-prompt","lastPrompt":"\#(text)"}"#
    }
}
