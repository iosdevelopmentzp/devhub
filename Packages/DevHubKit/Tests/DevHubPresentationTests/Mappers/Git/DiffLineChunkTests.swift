import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct DiffLineChunkTests {
    private let lines = (0..<50).map { DiffLineModel(id: $0, text: "line \($0)", tint: nil, foregroundOpacity: 1, backgroundOpacity: 0) }

    @Test func splitsIntoChunksOfTheGivenSizeWithTheFirstLineAsID() {
        let chunks = DiffLineChunk.chunks(of: lines, size: 24)

        #expect(chunks.map(\.id) == [0, 24, 48])
        #expect(chunks.map(\.elements.count) == [24, 24, 2])
        #expect(chunks.flatMap(\.elements) == lines)
    }

    @Test func emptyInputGivesNoChunks() {
        #expect(DiffLineChunk.chunks(of: [DiffLineModel](), size: 24).isEmpty)
    }

    @Test func standardSizeKeepsAHitTestCheap() {
        #expect(DiffLineChunk<DiffLineModel>.size == 24)
    }
}
