import Testing
@testable import DevHubDomain

@Suite struct GitChangeKindTests {
    @Test(arguments: [
        (GitChangeKind.modified, Character("M")),
        (.added, "A"),
        (.deleted, "D"),
        (.renamed, "R"),
        (.copied, "C"),
        (.untracked, "?"),
        (.conflicted, "U"),
        (.typeChanged, "T"),
        (.other("X"), "X"),
    ])
    func letterMatchesGitStatus(kind: GitChangeKind, letter: Character) {
        #expect(kind.letter == letter)
        #expect(GitChangeKind(letter: letter) == kind)
    }
}
