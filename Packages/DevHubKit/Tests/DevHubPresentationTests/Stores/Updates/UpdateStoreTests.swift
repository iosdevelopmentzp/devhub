import Foundation
import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct UpdateStoreTests {
    private let harness = StoreHarness()
    private let installed = InstalledBuild(commit: "0123456789abcdef0123456789abcdef01234567", branch: "main", source: "/Users/alex/source", installedAt: Date(timeIntervalSince1970: 1_700_000_000))
    private let commits = [UpdateCommit(hash: "a1b2c3d", subject: "feat: one"), UpdateCommit(hash: "d4e5f6a", subject: "fix: two")]
    private let startedAt = Date(timeIntervalSince1970: 1_799_999_900)

    private var spy: SpyUpdateRepository {
        harness.spies.updates
    }

    @Test func aDevelopmentBuildStaysIdleAndNeverChecks() async {
        await harness.updates.load()

        #expect(harness.updates.state == .idle)
        #expect(harness.updates.isInstalledBuild == false)
        #expect(spy.calls == [.installed])
    }

    @Test func anInstalledBuildChecksAtLaunchAndShowsTheCommits() async throws {
        spy.installedResult = .success(installed)
        spy.checkResult = .success(.available(commits))

        await harness.updates.load()

        try await waitUntil { self.harness.updates.state == .available(self.commits) }
        #expect(spy.calls.contains(.check(commit: installed.commit)))
        #expect(harness.activityTitles.contains("Update available"))
    }

    @Test func upToDateAndUnknownCommitsStayIdle() async throws {
        spy.installedResult = .success(installed)
        spy.checkResult = .success(.upToDate)
        await harness.updates.load()
        try await waitUntil { self.spy.calls.contains(.check(commit: self.installed.commit)) }
        await harness.settle()
        #expect(harness.updates.state == .idle)

        spy.checkResult = .success(.unknownInstalledCommit)
        await harness.updates.checkNow()

        #expect(harness.updates.state == .idle)
        #expect(harness.toaster.text?.contains("is not on origin/main") == true)
    }

    @Test func checkNowReportsUpToDate() async {
        spy.installedResult = .success(installed)
        spy.checkResult = .success(.upToDate)
        await harness.updates.load()

        await harness.updates.checkNow()

        #expect(harness.toaster.text == "DevHub is up to date (0123456)")
    }

    @Test func checkNowWithoutAnInstalledBuildExplains() async {
        await harness.updates.load()

        await harness.updates.checkNow()

        #expect(harness.toaster.text == "Updates need an installed build (Scripts/install.sh)")
        #expect(spy.calls == [.installed])
    }

    @Test func aFailedCheckIsLogged() async throws {
        spy.installedResult = .success(installed)
        spy.checkResult = .failure(TestError.scripted("offline"))
        await harness.updates.load()

        try await waitUntil { self.harness.activityTitles.contains("Update check failed") }
        #expect(harness.updates.state == .idle)
    }

    @Test func updateStartsTheScriptAndFollowsTheStatus() async throws {
        spy.installedResult = .success(installed)
        spy.checkResult = .success(.available(commits))
        spy.isRunning = true
        await harness.updates.load()
        try await waitUntil { self.harness.updates.state == .available(self.commits) }
        spy.statusResults = [.success(UpdateStatus(phase: .fetching, startedAt: startedAt)), .success(UpdateStatus(phase: .building, startedAt: startedAt))]

        await harness.updates.update()

        #expect(spy.calls.contains(.start(commit: installed.commit)))
        #expect(harness.updates.state == .running(.fetching, startedAt: Date(timeIntervalSince1970: 1_800_000_000)))
        try await waitUntil { self.harness.updates.state == .running(.building, startedAt: self.startedAt) }
        #expect(harness.activityTitles.contains("Update started"))
    }

    @Test func theInstallingPhaseAsksTheAppToQuitOnce() async throws {
        spy.installedResult = .success(installed)
        spy.isRunning = true
        var quits = 0
        harness.updates.onInstalling = { quits += 1 }
        await harness.updates.load()
        spy.statusResult = .success(UpdateStatus(phase: .installing, startedAt: startedAt))

        await harness.updates.update()

        try await waitUntil { quits == 1 }
        try await waitUntil { self.spy.calls.filter { $0 == .status }.count >= 3 }
        #expect(quits == 1)
        #expect(harness.updates.state == .running(.installing, startedAt: startedAt))
    }

    @Test func aFailedStatusEndsTheUpdateWithTheLog() async throws {
        spy.installedResult = .success(installed)
        spy.logResult = "xcodebuild: error\n"
        await harness.updates.load()
        spy.statusResult = .success(UpdateStatus(phase: .failed, startedAt: startedAt, message: "The build failed"))

        await harness.updates.update()

        try await waitUntil { self.harness.updates.state == .failed(message: "The build failed") }
        #expect(harness.updates.log == "xcodebuild: error\n")
        #expect(harness.activityTitles.contains("Update failed"))
    }

    @Test func aDeadUpdateProcessIsAFailure() async throws {
        spy.installedResult = .success(installed)
        spy.isRunning = false
        await harness.updates.load()
        spy.statusResult = .success(UpdateStatus(phase: .building, startedAt: startedAt))

        await harness.updates.update()

        try await waitUntil { self.harness.updates.state == .failed(message: UpdateLaunchPolicy.stoppedMessage) }
        #expect(spy.calls.contains(.clearStatus))
    }

    @Test func aDoneStatusWithoutAQuitReloadsTheInstalledBuild() async throws {
        spy.installedResult = .success(installed)
        await harness.updates.load()
        let newer = InstalledBuild(commit: "fedcba9876543210fedcba9876543210fedcba98", branch: "main", source: installed.source, installedAt: .now)
        spy.installedResult = .success(newer)
        spy.statusResult = .success(UpdateStatus(phase: .done, startedAt: startedAt, commit: newer.commit))

        await harness.updates.update()

        try await waitUntil { self.harness.updates.installed == newer }
        #expect(harness.updates.state == .idle)
        #expect(harness.toaster.text == "Updated to fedcba9")
        #expect(spy.calls.contains(.clearStatus))
    }

    @Test func aStartFailureIsShownAsFailed() async {
        spy.installedResult = .success(installed)
        spy.startError = UpdateError.alreadyRunning
        await harness.updates.load()

        await harness.updates.update()

        #expect(harness.updates.state == .failed(message: "An update is already running."))
        #expect(harness.activityTitles.contains("Update could not start"))
    }

    @Test func doneAfterLaunchShowsTheToastOnceAndClearsTheStatus() async {
        spy.installedResult = .success(installed)
        spy.statusResult = .success(UpdateStatus(phase: .done, startedAt: startedAt, commit: installed.commit))

        await harness.updates.load()

        #expect(harness.toaster.text == "Updated to 0123456")
        #expect(harness.updates.state == .idle)
        #expect(spy.calls.contains(.clearStatus))
        #expect(harness.activityTitles.contains("Updated to 0123456"))
    }

    @Test func doneForAnotherCommitAfterLaunchIsClearedQuietly() async {
        spy.installedResult = .success(installed)
        spy.statusResult = .success(UpdateStatus(phase: .done, startedAt: startedAt, commit: "ffffffff"))

        await harness.updates.load()

        #expect(harness.toaster.text == nil)
        #expect(spy.calls.contains(.clearStatus))
    }

    @Test func failedAfterLaunchKeepsTheFailureAndTheLog() async {
        spy.installedResult = .success(installed)
        spy.logResult = "error\n"
        spy.statusResult = .success(UpdateStatus(phase: .failed, startedAt: startedAt, message: "The build failed"))

        await harness.updates.load()

        #expect(harness.updates.state == .failed(message: "The build failed"))
        #expect(harness.updates.log == "error\n")
        #expect(spy.calls.contains(.clearStatus) == false)
    }

    @Test func aRunningStatusWithoutAProcessAfterLaunchIsAFailure() async {
        spy.installedResult = .success(installed)
        spy.isRunning = false
        spy.statusResult = .success(UpdateStatus(phase: .building, startedAt: startedAt))

        await harness.updates.load()

        #expect(harness.updates.state == .failed(message: UpdateLaunchPolicy.stoppedMessage))
        #expect(spy.calls.contains(.clearStatus))
    }

    @Test func aRunningStatusWithAProcessAfterLaunchIsFollowed() async throws {
        spy.installedResult = .success(installed)
        spy.isRunning = true
        spy.statusResults = [.success(UpdateStatus(phase: .building, startedAt: startedAt)), .success(UpdateStatus(phase: .installing, startedAt: startedAt))]

        await harness.updates.load()

        #expect(harness.updates.state == .running(.building, startedAt: startedAt))
        try await waitUntil { self.harness.updates.state == .running(.installing, startedAt: self.startedAt) }
    }

    @Test func checksSkipWhileAnUpdateRunsOrFailed() async throws {
        spy.installedResult = .success(installed)
        spy.statusResult = .success(UpdateStatus(phase: .failed, startedAt: startedAt, message: "The build failed"))
        await harness.updates.load()
        spy.checkResult = .success(.available(commits))

        await harness.updates.checkNow()

        #expect(spy.calls.contains(.check(commit: installed.commit)) == false)
        #expect(harness.updates.state == .failed(message: "The build failed"))
        #expect(harness.toaster.text == "The last update failed. Try again from the footer")
    }
}
