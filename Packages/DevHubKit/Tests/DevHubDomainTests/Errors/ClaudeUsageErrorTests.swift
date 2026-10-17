import Testing
@testable import DevHubDomain

@Suite struct ClaudeUsageErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [ClaudeUsageError] = [.notLoggedIn, .tokenExpired, .http(500), .malformedResponse]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func http401SaysTheTokenWasRejected() {
        #expect(ClaudeUsageError.http(401).errorDescription == "Token rejected (401). Run `claude` once to refresh it.")
    }

    @Test func otherHTTPCodesShowTheCode() {
        #expect(ClaudeUsageError.http(503).errorDescription == "Usage request failed (HTTP 503).")
    }
}
