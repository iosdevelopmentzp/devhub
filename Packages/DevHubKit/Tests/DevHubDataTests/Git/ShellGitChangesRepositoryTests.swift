import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct ShellGitChangesRepositoryTests {
    @Test func aPatchOfTheStagedChangesOrOfABranch() {
        #expect(ShellGitChangesRepository.patchArguments(.staged) == ["diff", "--cached", "--no-color", "--no-ext-diff"])
        #expect(ShellGitChangesRepository.patchArguments(.range(base: "origin/main", head: "feature/ABC-123-short-title")) == ["diff", "--no-color", "--no-ext-diff", "origin/main...feature/ABC-123-short-title"])
    }
}
