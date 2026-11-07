import Foundation
import Testing
@testable import DevHubData

@Suite struct DevicectlAppListParserTests {
    @Test func readsBundleIDsAndVersions() {
        let apps = DevicectlAppListParser.apps(from: DevicectlListFixture.apps)

        #expect(apps.map(\.bundleID) == ["com.example.app", "com.example.other"])
        #expect(apps.map(\.version) == ["1.5.2", nil])
    }

    @Test func brokenOutputGivesNoApps() {
        #expect(DevicectlAppListParser.apps(from: Data("nope".utf8)).isEmpty)
    }
}
