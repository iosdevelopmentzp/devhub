import DevHubDomain
import DevHubTestSupport
import Testing

@Suite struct TrackHiddenFileUseCaseTests {
    private let changed = GitHiddenFile(path: "Config/Local.xcconfig", flags: [.skipWorktree], state: .modified)
    private let same = GitHiddenFile(path: "Config/Local.xcconfig", flags: [.assumeUnchanged], state: .unchanged)

    @Test func keepingTheChangesOnlyClearsTheFlags() async throws {
        let (ports, spies) = Ports.spies()

        try await TrackHiddenFileUseCase(git: ports.git).execute(changed, mode: .keepChanges, checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.unhide(path: "Config/Local.xcconfig"), path: "/repo")])
    }

    @Test func stashingClearsTheFlagsFirstThenStashesTheFile() async throws {
        let (ports, spies) = Ports.spies()

        try await TrackHiddenFileUseCase(git: ports.git).execute(changed, mode: .stashChanges, checkoutPath: "/repo")

        #expect(spies.git.calls == [
            .perform(.unhide(path: "Config/Local.xcconfig"), path: "/repo"),
            .perform(.stashPath(path: "Config/Local.xcconfig", message: "Hidden changes of Config/Local.xcconfig"), path: "/repo"),
        ])
    }

    @Test func discardingClearsTheFlagsThenRestoresTheFile() async throws {
        let (ports, spies) = Ports.spies()

        try await TrackHiddenFileUseCase(git: ports.git).execute(changed, mode: .discardChanges, checkoutPath: "/repo")

        #expect(spies.git.calls == [
            .perform(.unhide(path: "Config/Local.xcconfig"), path: "/repo"),
            .perform(.restore(path: "Config/Local.xcconfig"), path: "/repo"),
        ])
    }

    @Test func aFileWithoutChangesHasNothingToStash() async throws {
        let (ports, spies) = Ports.spies()

        try await TrackHiddenFileUseCase(git: ports.git).execute(same, mode: .stashChanges, checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.unhide(path: "Config/Local.xcconfig"), path: "/repo")])
    }
}
