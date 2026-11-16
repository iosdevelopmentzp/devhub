import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct DoctorStoreTests {
    private let harness = StoreHarness()

    @Test func checkReadsEveryToolAndTheAccessibilityState() async {
        harness.spies.attacher.isTrusted = false

        await harness.doctor.check()

        #expect(harness.doctor.statuses.map(\.tool.name) == DoctorPolicy.tools.map(\.name))
        #expect(harness.doctor.statuses.allSatisfy { $0.isInstalled == false })
        #expect(harness.doctor.isAccessibilityTrusted == false)
        #expect(harness.doctor.isChecking == false)
    }

    @Test func checkReadsTheLoginOfTheCurrentCodeHost() async {
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        harness.spies.codeHost.accessResult = .success(CodeHostAccess(login: "alex", scopes: ["repo"]))

        await harness.doctor.check()

        #expect(harness.doctor.codeHostAccess?.host == .gitHubSample)
        #expect(harness.doctor.codeHostAccess?.result == .success(CodeHostAccess(login: "alex", scopes: ["repo"])))
        #expect(harness.spies.codeHost.calls == [.access(repository: .gitHubSample)])
    }

    @Test func aFailedLoginCheckIsKept() async {
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        harness.spies.codeHost.accessResult = .failure(PullRequestError.notLoggedIn(tool: "gh", host: "github.com"))

        await harness.doctor.check()

        #expect(harness.doctor.codeHostAccess?.result == .failure(.notLoggedIn(tool: "gh", host: "github.com")))
    }

    @Test func noCodeHostShowsNoLoginRow() async {
        await harness.doctor.check()

        #expect(harness.doctor.codeHostAccess == nil)
        #expect(harness.spies.codeHost.calls.isEmpty)
    }

    @Test func requestAccessibilityAsksTheSystem() {
        harness.doctor.requestAccessibility()

        #expect(harness.spies.attacher.calls.contains(.requestTrust))
    }
}
