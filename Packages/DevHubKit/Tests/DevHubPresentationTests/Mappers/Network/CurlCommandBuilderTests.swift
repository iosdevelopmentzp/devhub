import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct CurlCommandBuilderTests {
    @Test func aGetRequestIsOnlyTheURL() {
        #expect(CurlCommandBuilder.command(for: NetworkRequestFixture.profile) == "curl 'https://api-qa.example.com/v1/profile/info'")
    }

    @Test func aPostRequestHasTheMethodAndTheJSONBody() {
        var request = NetworkRequestFixture.profile
        request.method = "post"
        request.requestBody = #"{"text":"it's"}"#

        #expect(CurlCommandBuilder.command(for: request) == """
        curl -X POST 'https://api-qa.example.com/v1/profile/info' \\
          -H 'Content-Type: application/json' \\
          --data-raw '{"text":"it'\\''s"}'
        """)
    }

    @Test func neverAddsAnAuthorizationHeader() {
        var request = NetworkRequestFixture.profile
        request.responseHeaders = [HTTPHeader(name: "Authorization", value: "Bearer x")]

        #expect(CurlCommandBuilder.command(for: request).localizedCaseInsensitiveContains("authorization") == false)
    }
}
