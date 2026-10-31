import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIJSONTests {
    private struct Item: Decodable, Equatable {
        let runId: String
    }

    @Test func snakeCaseKeysAreRead() throws {
        #expect(try CircleCIJSON.decode(Item.self, from: Data(#"{"run_id":"r1"}"#.utf8)) == Item(runId: "r1"))
    }

    @Test func linesAndArraysAreBothRead() throws {
        #expect(try CircleCIJSON.decodeLines(Item.self, from: Data("{\"run_id\":\"a\"}\n  {\"run_id\":\"b\"}\n\n".utf8)) == [Item(runId: "a"), Item(runId: "b")])
        #expect(try CircleCIJSON.decodeLines(Item.self, from: Data(#"[{"run_id":"c"}]"#.utf8)) == [Item(runId: "c")])
    }

    @Test func aDecodingFailureIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIJSON.decode(Item.self, from: Data("{}".utf8))
        }
    }
}
