import Foundation
import Testing
@testable import DevHubData

@Suite struct LogRedactorTests {
    @Test(arguments: [
        ("Bearer abc123", "Bearer •••"),
        ("sent bearer abc.DEF-123_x~y+z/w== to server", "sent bearer ••• to server"),
        ("BEARER\tq1w2e3", "BEARER\t•••"),
    ])
    func masksBearerTokens(text: String, expected: String) {
        #expect(LogRedactor.redact(text) == expected)
    }

    @Test func masksJWTs() {
        let text = "jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl end"
        #expect(LogRedactor.redact(text) == "jwt ••• end")
    }

    @Test(arguments: [
        "authorization", "Authorization", "x-auth-token", "access_token", "accesstoken", "accessToken",
        "refresh_token", "refreshtoken", "id_token", "idtoken", "token", "password", "secret", "api_key", "apikey", "API_KEY",
    ])
    func masksEveryKeyForm(key: String) {
        #expect(LogRedactor.redact("\(key): value1") == "\(key): •••")
        #expect(LogRedactor.redact("\(key)=value1") == "\(key)=•••")
        #expect(LogRedactor.redact(#"{"\#(key)":"value1","next":1}"#) == #"{"\#(key)":"•••","next":1}"#)
    }

    @Test(arguments: [
        ("password=hunter2&next=1", "password=•••&next=1"),
        ("token = abc; other", "token = •••; other"),
        ("secret:abc,more", "secret:•••,more"),
        ("{token: abc}", "{token: •••}"),
    ])
    func stopsAtDelimiters(text: String, expected: String) {
        #expect(LogRedactor.redact(text) == expected)
    }

    @Test func authorizationHeaderWithBearerMasksBothWords() {
        #expect(LogRedactor.redact("Authorization: Bearer abc.def") == "Authorization: ••• •••")
    }

    @Test(arguments: [
        "GET /v1/profile/info 200 in 182 ms",
        "Call prompt shown for gift 42",
        "user=alice id=5 tokens 3",
        "Leaderboard {\"count\": 3, \"title\": \"Top\"}",
        "Tokenizer ready; secretary called",
        "Привіт 👋 ẞ\u{301}",
        "",
    ])
    func leavesUnrelatedTextByteIdentical(text: String) {
        #expect(Data(LogRedactor.redact(text).utf8) == Data(text.utf8))
    }
}
