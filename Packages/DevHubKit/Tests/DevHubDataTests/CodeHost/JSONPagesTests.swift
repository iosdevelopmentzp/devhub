import Foundation
import Testing
@testable import DevHubData

@Suite struct JSONPagesTests {
    @Test func splitsTopLevelValuesThatFollowEachOther() {
        let data = Data(#"[{"a":"]"}][{"b":"\"["}]  {"c":{"d":1}}"#.utf8)

        let pages = JSONPages.split(data).map { String(decoding: $0, as: UTF8.self) }

        #expect(pages == [#"[{"a":"]"}]"#, #"[{"b":"\"["}]"#, #"{"c":{"d":1}}"#])
    }

    @Test func textWithoutJSONHasNoPages() {
        #expect(JSONPages.split(Data("not json".utf8)).isEmpty)
    }
}
