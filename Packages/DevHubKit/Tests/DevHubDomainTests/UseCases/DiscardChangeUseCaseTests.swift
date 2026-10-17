import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct DiscardChangeUseCaseTests {
    @Test(arguments: [
        (GitFileChange.Area.untracked, GitCommand.cleanUntracked(path: "a.swift")),
        (.unstaged, .restore(path: "a.swift")),
        (.conflicted, .restore(path: "a.swift")),
        (.staged, .restoreStagedAndWorktree(path: "a.swift")),
    ])
    func areaChoosesTheCommand(area: GitFileChange.Area, command: GitCommand) async throws {
        let (ports, spies) = Ports.spies()
        let change = GitFileChange(path: "a.swift", originalPath: nil, area: area, kind: .modified)

        try await DiscardChangeUseCase(changes: ports.git).execute(change, checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(command, path: "/repo")])
    }
}
