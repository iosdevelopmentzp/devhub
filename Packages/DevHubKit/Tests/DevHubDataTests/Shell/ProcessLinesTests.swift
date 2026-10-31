import Foundation
import Testing
@testable import DevHubData

@Suite struct ProcessLinesTests {
    @Test func linesAreJoinedAcrossChunksAndTheTailIsDelivered() async throws {
        let pipe = Pipe()
        let writer = pipe.fileHandleForWriting
        let lines = ProcessLines.lines(of: pipe.fileHandleForReading)

        try writer.write(contentsOf: Data("a\nb".utf8))
        try writer.write(contentsOf: Data("c\r\n\nd".utf8))
        try writer.close()

        var collected: [String] = []
        for await line in lines {
            collected.append(line)
        }
        #expect(collected == ["a", "bc", "", "d"])
    }

    @Test func anEmptyPipeEndsTheStream() async throws {
        let pipe = Pipe()
        try pipe.fileHandleForWriting.close()

        var count = 0
        for await _ in ProcessLines.lines(of: pipe.fileHandleForReading) {
            count += 1
        }
        #expect(count == 0)
    }
}
