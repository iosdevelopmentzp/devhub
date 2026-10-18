import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct DoctorRowMapperTests {
    private let gh = DoctorPolicy.tools[3]

    @Test func aMissingToolOffersItsInstallCommand() {
        let model = DoctorRowMapper.model(for: ToolStatus(tool: gh, path: nil, version: nil))

        #expect(model.stateText == "missing")
        #expect(model.stateTint == .orange)
        #expect(model.installCommand == "brew install gh && gh auth login")
        #expect(model.path == nil)
    }

    @Test func aFoundToolShowsItsVersionAndPath() {
        let model = DoctorRowMapper.model(for: ToolStatus(tool: gh, path: "/opt/homebrew/bin/gh", version: "2.80.0"))

        #expect(model.stateText == "2.80.0")
        #expect(model.stateTint == .green)
        #expect(model.installCommand == nil)
        #expect(model.path == "/opt/homebrew/bin/gh")
    }

    @Test func accessibilityAndNotificationRows() {
        #expect(DoctorRowMapper.accessibility(isTrusted: false).stateText == "not allowed")
        #expect(DoctorRowMapper.accessibility(isTrusted: true).stateTint == .green)
        #expect(DoctorRowMapper.notifications(.denied).stateText == "denied")
        #expect(DoctorRowMapper.notifications(.allowed).stateTint == .green)
    }
}
