import Foundation
import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct NetworkRequestRowMapperTests {
    @Test func mapsASuccessfulRequest() {
        let model = NetworkRequestRowMapper.model(for: NetworkRequestFixture.profile, isSelected: true)

        #expect(model.id == 1)
        #expect(model.method == "GET")
        #expect(model.methodTint == .blue)
        #expect(model.path == "/v1/profile/info")
        #expect(model.host == "api-qa.example.com")
        #expect(model.status == "200")
        #expect(model.statusTint == .green)
        #expect(model.statusHint == "200 no error")
        #expect(model.duration == "182 ms")
        #expect(model.durationTint == .secondary)
        #expect(model.time.isEmpty == false)
        #expect(model.isSelected)
    }

    @Test(arguments: [
        ("GET", Tint.blue),
        ("POST", .green),
        ("PUT", .orange),
        ("patch", .orange),
        ("DELETE", .red),
        ("HEAD", .gray),
        ("", .gray),
    ])
    func tintsTheMethod(method: String, tint: Tint) {
        #expect(NetworkRequestRowMapper.methodTint(method) == tint)
    }

    @Test(arguments: [
        (Optional(204), String?.none, false, Tint.green, "204"),
        (301, nil, false, .orange, "301"),
        (404, nil, true, .orange, "404"),
        (500, nil, true, .red, "500"),
        (200, "decoding failed", true, .red, "200"),
        (nil, "timed out", true, .red, "Failed"),
        (nil, nil, false, .gray, "—"),
        (nil, nil, true, .red, "—"),
    ])
    func tintsTheStatus(statusCode: Int?, error: String?, isFailure: Bool, tint: Tint, text: String) {
        let request = NetworkRequestFixture.with(method: "GET", statusCode: statusCode, error: error, isFailure: isFailure, duration: nil)

        let model = NetworkRequestRowMapper.model(for: request, isSelected: false)

        #expect(model.statusTint == tint)
        #expect(model.status == text)
    }

    @Test func theHintNamesTheErrorOrTheMissingResponse() {
        let failed = NetworkRequestFixture.with(method: "GET", statusCode: nil, error: "timed out", isFailure: true, duration: nil)
        let pending = NetworkRequestFixture.with(method: "GET", statusCode: nil, error: nil, isFailure: false, duration: nil)
        var noText = NetworkRequestFixture.profile
        noText.statusText = ""

        #expect(NetworkRequestRowMapper.model(for: failed, isSelected: false).statusHint == "timed out")
        #expect(NetworkRequestRowMapper.model(for: pending, isSelected: false).statusHint == "No response yet")
        #expect(NetworkRequestRowMapper.model(for: noText, isSelected: false).statusHint == "200")
    }

    @Test func aSlowRequestHasAnOrangeDurationAndNoDurationIsEmpty() {
        let slow = NetworkRequestFixture.with(method: "GET", statusCode: 200, error: nil, isFailure: false, duration: 2.5)
        let unknown = NetworkRequestFixture.with(method: "GET", statusCode: 200, error: nil, isFailure: false, duration: nil)

        #expect(NetworkRequestRowMapper.model(for: slow, isSelected: false).durationTint == .orange)
        #expect(NetworkRequestRowMapper.model(for: slow, isSelected: false).duration == "2.5 s")
        #expect(NetworkRequestRowMapper.model(for: unknown, isSelected: false).duration.isEmpty)
    }

    @Test func fallsBackToTheURLAndAQuestionMark() {
        var request = NetworkRequestFixture.profile
        request.path = ""
        request.method = ""

        let model = NetworkRequestRowMapper.model(for: request, isSelected: false)

        #expect(model.path == request.url)
        #expect(model.method == "?")
    }

    @Test func serverRowsAreTaggedMockedOrViaDevHub() {
        var forwarded = NetworkRequestFixture.profile
        var mocked = forwarded
        mocked.mockRuleID = UUID()

        #expect(NetworkRequestRowMapper.model(for: forwarded, isSelected: false).tags == [NetworkRequestRowMapper.passthroughTag])
        #expect(NetworkRequestRowMapper.model(for: mocked, isSelected: false).tags == [NetworkRequestRowMapper.mockedTag])
        #expect(NetworkRequestRowMapper.mockedTag.tint == .purple)
        #expect(NetworkRequestRowMapper.passthroughTag.tint == .indigo)
    }
}
