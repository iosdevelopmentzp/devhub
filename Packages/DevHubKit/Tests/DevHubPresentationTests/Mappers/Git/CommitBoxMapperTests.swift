import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct CommitBoxMapperTests {
    let staged = GitFileChange(path: "App/Login.swift", originalPath: nil, area: .staged, kind: .modified)

    @Test func conflictsComeFirst() {
        let model = CommitBoxMapper.model(staged: [staged], conflictedCount: 2, isAmend: false, canCommit: false, isGitBusy: false, branch: "main")

        #expect(model.summary == "Resolve 2 conflicts first")
    }

    @Test func nothingStagedAsksToStage() {
        let model = CommitBoxMapper.model(staged: [], conflictedCount: 0, isAmend: false, canCommit: false, isGitBusy: false, branch: "main")

        #expect(model.summary == "Stage files to commit")
    }

    @Test func amendWithNothingStagedCountsZeroFiles() {
        let model = CommitBoxMapper.model(staged: [], conflictedCount: 0, isAmend: true, canCommit: true, isGitBusy: false, branch: nil)

        #expect(model.summary == "0 staged files on HEAD")
    }

    @Test func stagedFilesAreCountedByPath() {
        let renamed = GitFileChange(path: "App/Login.swift", originalPath: "App/Old.swift", area: .staged, kind: .renamed)
        let other = GitFileChange(path: "App/Home.swift", originalPath: nil, area: .staged, kind: .added)

        let one = CommitBoxMapper.model(staged: [staged, renamed], conflictedCount: 0, isAmend: false, canCommit: true, isGitBusy: false, branch: "feature/login")
        let two = CommitBoxMapper.model(staged: [staged, other], conflictedCount: 0, isAmend: false, canCommit: true, isGitBusy: false, branch: "feature/login")

        #expect(one.summary == "1 staged file on feature/login")
        #expect(two.summary == "2 staged files on feature/login")
    }

    @Test func commitAndPushNeedsAnIdleGit() {
        let idle = CommitBoxMapper.model(staged: [staged], conflictedCount: 0, isAmend: false, canCommit: true, isGitBusy: false, branch: "main")
        let busy = CommitBoxMapper.model(staged: [staged], conflictedCount: 0, isAmend: false, canCommit: true, isGitBusy: true, branch: "main")
        let blocked = CommitBoxMapper.model(staged: [staged], conflictedCount: 0, isAmend: false, canCommit: false, isGitBusy: false, branch: "main")

        #expect(idle.canCommit && idle.canCommitAndPush)
        #expect(busy.canCommit && busy.canCommitAndPush == false)
        #expect(blocked.canCommit == false && blocked.canCommitAndPush == false)
    }
}
