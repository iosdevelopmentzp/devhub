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

    @Test func aToolBelowItsMinimumVersionWarnsAndOffersTheUpgrade() {
        let circleci = DoctorPolicy.tools[5]
        let old = DoctorRowMapper.model(for: ToolStatus(tool: circleci, path: "/opt/homebrew/bin/circleci", version: "0.1.31425"))
        let current = DoctorRowMapper.model(for: ToolStatus(tool: circleci, path: "/opt/homebrew/bin/circleci", version: "1.13.0"))

        #expect(old.stateText == "0.1.31425, needs 1 or newer")
        #expect(old.stateTint == .orange)
        #expect(old.icon == "exclamationmark.triangle.fill")
        #expect(old.installCommand == "brew upgrade circleci")
        #expect(current.stateText == "1.13.0")
        #expect(current.stateTint == .green)
        #expect(current.installCommand == nil)
    }

    @Test func aToolWithANewerVersionOffersTheUpgrade() {
        let circleci = DoctorPolicy.tools[5]

        let model = DoctorRowMapper.model(for: ToolStatus(tool: circleci, path: "/opt/homebrew/bin/circleci", version: "1.13.0", latestVersion: "1.14.0"))

        #expect(model.stateText == "1.13.0, 1.14.0 available")
        #expect(model.stateTint == .blue)
        #expect(model.icon == "arrow.down.circle.fill")
        #expect(model.installCommand == "brew upgrade circleci")
    }
}
