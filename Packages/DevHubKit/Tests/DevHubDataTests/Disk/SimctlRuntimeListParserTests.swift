import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct SimctlRuntimeListParserTests {
    @Test func deletableRuntimesBecomeItemsNewestFirst() throws {
        let items = try SimctlRuntimeListParser.items(from: Data(DiskCleanupFixture.runtimeList.utf8))

        #expect(items.map(\.name) == ["watchOS 26.0", "iOS 26.4", "iOS 18.6"])
        let latest = try #require(items.first { $0.name == "iOS 26.4" })
        #expect(latest.id == "runtime:4B1E1916-0D85-4542-9D9D-DC46F18796C9")
        #expect(latest.kind == .simulatorRuntime)
        #expect(latest.detail == "23E244")
        #expect(latest.size == 8_485_747_282)
        #expect(latest.runtimeID == "4B1E1916-0D85-4542-9D9D-DC46F18796C9")
        #expect(latest.lastUsed == ISO8601.date(from: "2026-04-17T12:10:38Z"))
    }

    @Test func missingFieldsStayEmpty() throws {
        let items = try SimctlRuntimeListParser.items(from: Data(DiskCleanupFixture.runtimeList.utf8))

        let watch = try #require(items.first)
        #expect(watch.size == nil)
        #expect(watch.lastUsed == nil)
    }

    @Test func anEmptyListHasNoItems() throws {
        #expect(try SimctlRuntimeListParser.items(from: Data("{}".utf8)).isEmpty)
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: DiskCleanupError.self) {
            try SimctlRuntimeListParser.items(from: Data("not json".utf8))
        }
    }

    @Test func platformNames() {
        #expect(SimctlRuntimeListParser.platformName("com.apple.platform.appletvsimulator") == "tvOS")
        #expect(SimctlRuntimeListParser.platformName("com.apple.platform.xrsimulator") == "visionOS")
        #expect(SimctlRuntimeListParser.platformName("com.example.platform.othersimulator") == "othersimulator")
        #expect(SimctlRuntimeListParser.platformName(nil) == nil)
    }
}
