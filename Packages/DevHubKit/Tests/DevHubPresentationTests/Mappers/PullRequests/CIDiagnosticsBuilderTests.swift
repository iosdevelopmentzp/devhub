import Foundation
import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct CIDiagnosticsBuilderTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ command: String, lines: [String] = [], exitCode: Int32? = 0, error: String? = nil, dropped: Int = 0) -> CommandLog.Entry {
        CommandLog.Entry(id: UUID(), command: command, cwd: "/Users/alex/Projects/app", kind: .read, operationID: nil, startedAt: date, finishedAt: date.addingTimeInterval(1.5), exitCode: exitCode, error: error, lines: lines, droppedLines: dropped)
    }

    private func event(_ title: String, detail: String = "", outcome: ActivityEvent.Outcome = .failure, kind: NotificationKind? = nil) -> ActivityEvent {
        ActivityEvent(id: UUID(), title: title, detail: detail, date: date, outcome: outcome, kind: kind, target: nil)
    }

    private var facts: CIDiagnosticsBuilder.Facts {
        CIDiagnosticsBuilder.Facts(
            appVersion: "1.2",
            date: date,
            provider: .circleci,
            slug: "gh/example/app",
            checkoutPath: "/Users/alex/Projects/app",
            ciConfig: CIConfig(kind: "circleci", project: nil),
            hostKind: .github,
            currentBranch: "feature/ABC-123-short-title",
            baseBranch: "main",
            toolState: CIToolState(isInstalled: true, version: "1.14.0", isLoggedIn: true),
            toolError: nil,
            snapshot: CIDiagnosticsSnapshot(
                requestReference: "#7",
                requestWorkflows: [CIWorkflow(id: "w1", name: "build-and-test", status: .failed, runID: "run-1", jobs: [CIJob(id: "j1", name: "unit-tests", status: .failed, isApproval: false), CIJob(id: "j2", name: "approve", status: .manual, isApproval: true)])],
                requestWorkflowErrors: ["w2": "not found"],
                branchRun: CIRun(id: "run-1", status: .failed, branch: "feature/ABC-123-short-title", revision: "abc1234", subject: "ABC-123: Login", createdAt: date),
                branchWorkflows: [CIWorkflow(id: "w1", name: "build-and-test", status: .failed, runID: "run-1", jobs: [])],
                baseRun: nil,
                baseWorkflows: []
            ),
            failures: [event("Auto re-run of #7 stopped", detail: "No re-run: unit-tests failed on a test that is not flaky")],
            commands: [entry("circleci workflow get w1 --json", lines: ["{", "  \"name\": \"build-and-test\"", "}"]), entry("circleci run list --branch main", exitCode: 4, error: "exit 4")]
        )
    }

    @Test func theTextHasEverySectionInOrder() {
        let text = CIDiagnosticsBuilder.text(facts)

        #expect(text == """
        DevHub CI diagnostics
        Date: 2027-01-15T08:00:00Z
        DevHub: 1.2

        ## Project
        Provider: circleci
        Slug: gh/example/app
        Checkout: /Users/alex/Projects/app
        Host: github
        Config ci: kind=circleci project=-
        Branch: feature/ABC-123-short-title, base: main
        CLI: circleci 1.14.0, logged in

        ## Workflows of #7
        build-and-test failed id=w1 run=run-1
          job unit-tests failed id=j1
          job approve manual (approval) id=j2
        error w2: not found

        ## Latest run of the branch
        run-1 failed branch=feature/ABC-123-short-title rev=abc1234 created=2027-01-15T08:00:00Z subject=ABC-123: Login
          workflow build-and-test failed id=w1

        ## Latest run of the base branch
        none

        ## Recent CI failures
        2027-01-15T08:00:00Z Auto re-run of #7 stopped — No re-run: unit-tests failed on a test that is not flaky

        ## Commands (last 2 of circleci)

        ### 2027-01-15T08:00:00Z exit 0 1.5 s cwd=/Users/alex/Projects/app
        $ circleci workflow get w1 --json
        {
          "name": "build-and-test"
        }

        ### 2027-01-15T08:00:00Z exit 4 1.5 s cwd=/Users/alex/Projects/app
        $ circleci run list --branch main
        error: exit 4

        """)
    }

    @Test func theToolLineFollowsTheState() {
        var facts = facts
        facts.toolState = nil
        #expect(CIDiagnosticsBuilder.text(facts).contains("CLI: not checked\n"))

        facts.toolState = .missing
        #expect(CIDiagnosticsBuilder.text(facts).contains("CLI: not installed\n"))

        facts.toolState = CIToolState(isInstalled: true, version: nil, isLoggedIn: false)
        #expect(CIDiagnosticsBuilder.text(facts).contains("CLI: circleci unknown version, not logged in\n"))

        facts.toolError = "offline"
        #expect(CIDiagnosticsBuilder.text(facts).contains("CLI: unavailable (offline)\n"))
    }

    @Test func aLongOutputKeepsItsHeadAndTail() {
        var facts = facts
        facts.commands = [entry("circleci job output list j1", lines: (1...100).map { "line \($0)" }, dropped: 12)]

        let text = CIDiagnosticsBuilder.text(facts)

        #expect(text.contains("(12 earlier lines dropped by the command log)\nline 1\n"))
        #expect(text.contains("line 40\n(20 lines left out)\nline 61\n"))
        #expect(text.contains("line 100\n"))
        #expect(text.contains("line 50\n") == false)
    }

    @Test func onlyTheLastCircleCICommandsAreKept() {
        let entries = [entry("git status")] + (1...45).map { entry("/opt/homebrew/bin/circleci workflow get w\($0) --json") } + [entry("gh pr view 7")]

        let kept = CIDiagnosticsBuilder.ciCommands(in: entries)

        #expect(kept.count == CIDiagnosticsBuilder.commandLimit)
        #expect(kept.first?.command.hasSuffix("w6 --json") == true)
        #expect(kept.last?.command.hasSuffix("w45 --json") == true)
    }

    @Test func onlyCIFailuresAreKept() {
        let events = [
            event("Push failed"),
            event("CircleCI: build-and-test failed"),
            event("Cannot read the flaky tests of CircleCI"),
            event("CI of dev failed: nightly"),
            event("Auto re-run of #7 gave up"),
            event("Checks of #7 passed", outcome: .success, kind: .requestChecks),
            event("Re-run 1 of 3", outcome: .info, kind: .requestChecks),
            event("approve of #7 waits", kind: .requestApprovals),
        ]

        #expect(CIDiagnosticsBuilder.ciFailures(in: events).map(\.title) == [
            "CircleCI: build-and-test failed",
            "Cannot read the flaky tests of CircleCI",
            "CI of dev failed: nightly",
            "Auto re-run of #7 gave up",
            "approve of #7 waits",
        ])
    }
}
