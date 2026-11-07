import Foundation
import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct UpdateIndicatorMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_080)
    private let commits = [UpdateCommit(hash: "a1b2c3d", subject: "feat: one"), UpdateCommit(hash: "d4e5f6a", subject: "fix: two")]

    @Test func idleIsHidden() {
        #expect(UpdateIndicatorMapper.model(for: .idle, remoteBranch: "origin/main", now: now) == nil)
    }

    @Test func availableListsTheCommits() throws {
        let model = try #require(UpdateIndicatorMapper.model(for: .available(commits), remoteBranch: "origin/main", now: now))

        #expect(model.text == "Update available · 2")
        #expect(model.icon == "arrow.down.circle.fill")
        #expect(model.tint == .blue)
        #expect(model.isRunning == false)
        #expect(model.canOpen)
        #expect(model.title == "2 new commits on origin/main")
        #expect(model.commits == [
            UpdateCommitRowModel(id: "a1b2c3d", hash: "a1b2c3d", subject: "feat: one"),
            UpdateCommitRowModel(id: "d4e5f6a", hash: "d4e5f6a", subject: "fix: two"),
        ])
        #expect(model.actionTitle == "Update Now")
        #expect(model.showsLog == false)
        #expect(model.hint == UpdateIndicatorMapper.availableHint)
    }

    @Test func oneCommitIsSingular() throws {
        let model = try #require(UpdateIndicatorMapper.model(for: .available([commits[0]]), remoteBranch: "origin/dev", now: now))

        #expect(model.title == "1 new commit on origin/dev")
    }

    @Test func runningShowsThePhaseAndTheTime() throws {
        let model = try #require(UpdateIndicatorMapper.model(for: .running(.building, startedAt: Date(timeIntervalSince1970: 1_800_000_000)), remoteBranch: "origin/main", now: now))

        #expect(model.text == "Building · 1:20")
        #expect(model.isRunning)
        #expect(model.canOpen == false)
        #expect(model.actionTitle == nil)
        #expect(model.hint == UpdateIndicatorMapper.runningHint)
    }

    @Test func failedOffersTheLogAndTryAgain() throws {
        let model = try #require(UpdateIndicatorMapper.model(for: .failed(message: "The build failed"), remoteBranch: "origin/main", now: now))

        #expect(model.text == "Update failed")
        #expect(model.icon == "exclamationmark.triangle.fill")
        #expect(model.tint == .orange)
        #expect(model.canOpen)
        #expect(model.failure == "The build failed")
        #expect(model.showsLog)
        #expect(model.actionTitle == "Try Again")
        #expect(model.hint == UpdateIndicatorMapper.failedHint)
    }
}
