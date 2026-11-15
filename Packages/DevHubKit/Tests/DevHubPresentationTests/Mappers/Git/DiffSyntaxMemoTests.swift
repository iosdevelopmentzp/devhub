import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct DiffSyntaxMemoTests {
    @Test func theSameLinesAreLexedOnceAndTheOldestEntryLeavesAtTheLimit() {
        let memo = DiffSyntaxMemo()
        let lines = ["@@ -1 +1 @@", "+let a = 1"]

        let first = memo.tokens(forHunkLines: lines, language: .swift)
        let second = memo.tokens(forHunkLines: lines, language: .swift)

        #expect(first == DiffSyntaxPolicy.tokens(forHunkLines: lines, language: .swift))
        #expect(first == second)
        #expect(memo.count == 1)

        for index in 0..<DiffSyntaxMemo.limit {
            _ = memo.tokens(forHunkLines: ["+let x\(index) = \(index)"], language: .swift)
        }

        #expect(memo.count == DiffSyntaxMemo.limit)
    }

    @Test func twoMemosAreEqualOnlyWhenTheyAreTheSameObject() {
        let memo = DiffSyntaxMemo()

        #expect(memo == memo)
        #expect(memo != DiffSyntaxMemo())
    }
}
