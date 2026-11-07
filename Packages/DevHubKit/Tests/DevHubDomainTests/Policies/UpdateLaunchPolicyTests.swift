import Foundation
import Testing
@testable import DevHubDomain

@Suite struct UpdateLaunchPolicyTests {
    private let installed = InstalledBuild(commit: "0123456789abcdef0123456789abcdef01234567", branch: "main", source: "/Users/alex/source", installedAt: Date(timeIntervalSince1970: 1_800_000_000))
    private let startedAt = Date(timeIntervalSince1970: 1_800_000_100)

    @Test func noStatusMeansNothingToDo() {
        #expect(UpdateLaunchPolicy.outcome(status: nil, installed: installed, isUpdateRunning: false) == .nothing)
    }

    @Test func doneWithTheInstalledCommitIsAnUpdate() {
        let status = UpdateStatus(phase: .done, startedAt: startedAt, commit: installed.commit)

        #expect(UpdateLaunchPolicy.outcome(status: status, installed: installed, isUpdateRunning: false) == .updated(commit: installed.commit))
    }

    @Test func doneWithAnotherCommitOnlyClearsTheStatus() {
        let status = UpdateStatus(phase: .done, startedAt: startedAt, commit: "ffffffff")

        #expect(UpdateLaunchPolicy.outcome(status: status, installed: installed, isUpdateRunning: false) == .clearStatus)
    }

    @Test func failedKeepsItsMessageOrGetsTheDefault() {
        let withMessage = UpdateStatus(phase: .failed, startedAt: startedAt, message: "The build failed")
        let without = UpdateStatus(phase: .failed, startedAt: startedAt)

        #expect(UpdateLaunchPolicy.outcome(status: withMessage, installed: installed, isUpdateRunning: false) == .failed(message: "The build failed"))
        #expect(UpdateLaunchPolicy.outcome(status: without, installed: installed, isUpdateRunning: false) == .failed(message: UpdateLaunchPolicy.noMessage))
    }

    @Test func aRunningPhaseNeedsALiveProcess() {
        for phase in [UpdatePhase.fetching, .building, .installing] {
            let status = UpdateStatus(phase: phase, startedAt: startedAt)

            #expect(UpdateLaunchPolicy.outcome(status: status, installed: installed, isUpdateRunning: true) == .running(status))
            #expect(UpdateLaunchPolicy.outcome(status: status, installed: installed, isUpdateRunning: false) == .stopped)
        }
    }
}
