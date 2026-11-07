import Foundation
import Testing
@testable import DevHubData

@Suite struct DevicectlLaunchParserTests {
    @Test func readsTheProcessIdentifier() {
        #expect(DevicectlLaunchParser.pid(from: DevicectlListFixture.launch) == 23581)
    }

    @Test func missingProcessGivesNil() {
        #expect(DevicectlLaunchParser.pid(from: Data("{\"result\": {}}".utf8)) == nil)
        #expect(DevicectlLaunchParser.pid(from: Data("nope".utf8)) == nil)
    }
}
