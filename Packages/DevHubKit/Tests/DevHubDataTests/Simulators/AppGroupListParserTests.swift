import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct AppGroupListParserTests {
    @Test func readsTheGroupIDAndThePath() {
        let groups = AppGroupListParser.groups(from: DefaultsExportFixture.groups)

        #expect(groups.map(\.name) == ["group.com.example.app", "group.com.example.app.widgets"])
        #expect(groups.last?.path == "/Users/alex/Library/Developer/CoreSimulator/Devices/U1/data/Containers/Shared/AppGroup/G 2")
        #expect(groups.allSatisfy { $0.size == 0 })
    }

    @Test func skipsLinesWithoutAPath() {
        #expect(AppGroupListParser.groups(from: "No app groups\n\n").isEmpty)
        #expect(AppGroupListParser.groups(from: "").isEmpty)
    }
}
