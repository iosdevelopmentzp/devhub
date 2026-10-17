import Foundation
import Testing
@testable import DevHubData

@Suite struct ClaudeCredentialsTests {
    @Test(arguments: [
        (Date?.none, false),
        (Date.distantPast, true),
        (Date.distantFuture, false),
    ])
    func isExpired(expiresAt: Date?, expected: Bool) {
        let credentials = ClaudeCredentials(accessToken: "token", expiresAt: expiresAt, subscriptionType: nil)
        #expect(credentials.isExpired == expected)
    }
}
