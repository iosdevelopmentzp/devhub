import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct TrackerToolMapperTests {
    @Test func whileLookingTheCardIsCompactAndWorking() {
        let model = TrackerToolMapper.model(for: nil, isChecking: true)

        #expect(model.title == "Looking for jira…")
        #expect(model.isWorking)
        #expect(model.isCompact)
        #expect(model.showsCheckAgain == false)
    }

    @Test func aReadyToolShowsTheVersionAndTheUser() {
        let model = TrackerToolMapper.model(for: .ready(version: "1.7.0", user: "alex@example.com"), isChecking: false)

        #expect(model.title == "jira 1.7.0")
        #expect(model.detail == "alex@example.com")
        #expect(model.tint == .green)
        #expect(model.isCompact)
        #expect(model.command == nil)
        #expect(TrackerToolMapper.model(for: .ready(version: nil, user: nil), isChecking: false).title == "jira")
    }

    @Test func aMissingToolOffersTheInstallCommand() {
        let model = TrackerToolMapper.model(for: .missing, isChecking: false)

        #expect(model.title == "jira is not installed")
        #expect(model.command == "brew install jira-cli")
        #expect(model.tint == .orange)
        #expect(model.showsCheckAgain)
        #expect(model.isCompact == false)
    }

    @Test func aToolWithoutAConfigOrATokenSaysWhatToRun() {
        #expect(TrackerToolMapper.model(for: .notConfigured, isChecking: false).command == "jira init")
        #expect(TrackerToolMapper.model(for: .notLoggedIn, isChecking: false).command == "security add-generic-password -s jira-cli -a <your login> -w <api token>")
        #expect(TrackerToolMapper.model(for: .notLoggedIn, isChecking: true).isWorking)
    }

    @Test func aFailureShowsTheMessageInRed() {
        let model = TrackerToolMapper.model(for: .failed("Get https://jira.example.com: no route to host"), isChecking: false)

        #expect(model.title == "jira failed")
        #expect(model.detail == "Get https://jira.example.com: no route to host")
        #expect(model.tint == .red)
        #expect(model.showsCheckAgain)
    }
}
