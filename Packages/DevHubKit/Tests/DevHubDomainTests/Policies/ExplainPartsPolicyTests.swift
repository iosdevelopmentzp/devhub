import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ExplainPartsPolicyTests {
    private func file(_ name: String, size: Int) -> PullRequestFileDiff {
        PullRequestFileDiff(oldPath: name, path: name, kind: .modified, additions: 1, deletions: 0, diff: GitDiff(lines: [String(repeating: "x", count: size)], droppedLines: 0, isBinary: false), isTooLarge: false)
    }

    @Test func smallFilesShareOnePart() {
        let plan = ExplainPartsPolicy.plan([file("a", size: 10), file("b", size: 10)], limit: 1_000)

        #expect(plan.parts.map { $0.map(\.path) } == [["a", "b"]])
        #expect(plan.leftOut.isEmpty)
    }

    @Test func aPartEndsBeforeTheLimitAndABigFileGetsItsOwnPart() {
        let plan = ExplainPartsPolicy.plan([file("a", size: 300), file("b", size: 300), file("huge", size: 5_000), file("c", size: 10)], limit: 700)

        #expect(plan.parts.map { $0.map(\.path) } == [["a", "b"], ["huge"], ["c"]])
    }

    @Test func filesAfterTheFifthPartAreLeftOut() {
        let files = (0..<8).map { file("f\($0)", size: 900) }

        let plan = ExplainPartsPolicy.plan(files, limit: 1_000)

        #expect(plan.parts.count == ExplainPartsPolicy.partLimit)
        #expect(plan.leftOut == ["f5", "f6", "f7"])
    }

    @Test func answersAreJoinedUnderPartHeaders() {
        #expect(ExplainPartsPolicy.joined(["Only"], leftOut: []) == "Only")
        #expect(ExplainPartsPolicy.joined(["One", "Two"], leftOut: ["z.swift"]) == "### Part 1 of 2\n\nOne\n\n### Part 2 of 2\n\nTwo\n\n### Not explained\n\nThe diff is too large for 5 parts. These files were left out: z.swift.")
    }

    @Test func aPartPromptNamesItsPartAndOnlyItsChangedFiles() {
        let prompt = AITextPromptBuilder.explain(title: "T", description: "", files: [file("a", size: 1)], changedSinceReview: ["a", "b"], noun: "pull request", part: 2, of: 3)

        #expect(prompt.contains("This is part 2 of 3: explain only the files in this part."))
        #expect(prompt.contains("describe only these files: a."))
    }
}
