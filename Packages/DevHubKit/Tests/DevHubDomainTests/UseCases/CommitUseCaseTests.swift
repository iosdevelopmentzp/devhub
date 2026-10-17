import DevHubTestSupport
import Foundation
import Synchronization
import Testing
@testable import DevHubDomain

@Suite struct CommitUseCaseTests {
    @Test func commitsWithoutPushWhenNotAsked() async throws {
        let (ports, spies) = Ports.spies()

        let result = try await commit(git: ports.git, amend: false, thenPush: false, branch: "feature", upstream: nil)

        #expect(spies.git.calls == [.perform(.commit(message: "Fix login", amend: false), path: "/repo")])
        #expect(isSkipped(result))
    }

    @Test func amendFlagIsPassed() async throws {
        let (ports, spies) = Ports.spies()

        _ = try await commit(git: ports.git, amend: true, thenPush: false, branch: "feature", upstream: nil)

        #expect(spies.git.calls == [.perform(.commit(message: "Fix login", amend: true), path: "/repo")])
    }

    @Test func skipsThePushOnADetachedHead() async throws {
        let (ports, spies) = Ports.spies()

        let result = try await commit(git: ports.git, amend: false, thenPush: true, branch: nil, upstream: nil)

        #expect(spies.git.calls == [.perform(.commit(message: "Fix login", amend: false), path: "/repo")])
        #expect(isSkipped(result))
    }

    @Test func pushesAfterTheCommitAndSetsUpstreamWhenMissing() async throws {
        let (ports, spies) = Ports.spies()

        let result = try await commit(git: ports.git, amend: false, thenPush: true, branch: "feature", upstream: nil)

        #expect(spies.git.calls == [
            .perform(.commit(message: "Fix login", amend: false), path: "/repo"),
            .perform(.push(branch: "feature", setUpstream: true), path: "/repo"),
        ])
        guard case .pushed(let branch) = result else {
            Issue.record("Expected .pushed, got \(result)")
            return
        }
        #expect(branch == "feature")
    }

    @Test func pushWithUpstreamDoesNotSetIt() async throws {
        let (ports, spies) = Ports.spies()

        _ = try await commit(git: ports.git, amend: false, thenPush: true, branch: "feature", upstream: "origin/feature")

        #expect(spies.git.calls.last == .perform(.push(branch: "feature", setUpstream: false), path: "/repo"))
    }

    @Test func failedPushAfterACommitIsReportedNotThrown() async throws {
        let git = PushFailingGitRepository()

        let result = try await commit(git: git, amend: false, thenPush: true, branch: "feature", upstream: "origin/feature")

        #expect(git.commands == [.commit(message: "Fix login", amend: false), .push(branch: "feature", setUpstream: false)])
        guard case .failed(let branch, let error) = result else {
            Issue.record("Expected .failed, got \(result)")
            return
        }
        #expect(branch == "feature")
        #expect(error as? TestError == .scripted("push rejected"))
    }

    @Test func failedCommitIsThrownAndNothingIsPushed() async {
        let (ports, spies) = Ports.spies()
        spies.git.performError = TestError.scripted("nothing to commit")

        await #expect(throws: TestError.scripted("nothing to commit")) {
            try await commit(git: ports.git, amend: false, thenPush: true, branch: "feature", upstream: nil)
        }
        #expect(spies.git.calls == [.perform(.commit(message: "Fix login", amend: false), path: "/repo")])
    }

    private func commit(git: any GitRepository, amend: Bool, thenPush: Bool, branch: String?, upstream: String?) async throws -> CommitUseCase.PushResult {
        try await CommitUseCase(git: git).execute(
            message: "Fix login",
            amend: amend,
            thenPush: thenPush,
            branch: branch,
            upstream: upstream,
            checkoutPath: "/repo"
        )
    }

    private func isSkipped(_ result: CommitUseCase.PushResult) -> Bool {
        guard case .skipped = result else { return false }
        return true
    }
}

private final class PushFailingGitRepository: GitRepository {
    private let recorded = Mutex<[GitCommand]>([])

    var commands: [GitCommand] {
        recorded.withLock { $0 }
    }

    func state(checkoutPath: String, mainPath: String) async throws -> GitRepositoryState {
        throw TestError.scripted("state")
    }

    func perform(_ command: GitCommand, in path: String) async throws {
        recorded.withLock { $0.append(command) }
        guard case .push = command else { return }
        throw TestError.scripted("push rejected")
    }

    func webURL(checkoutPath: String) async -> URL? {
        nil
    }

    func commitSubjects(from base: String, to head: String, in path: String) async throws -> [String] {
        []
    }

    func mergeRequestTemplate(in path: String) async -> String? {
        nil
    }
}
