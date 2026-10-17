import Foundation
import Testing
@testable import DevHubDomain

@Suite struct StringPathsTests {
    @Test func abbreviatesTheHomeFolder() {
        #expect((NSHomeDirectory() + "/Developer/App").abbreviatingHome == "~/Developer/App")
    }

    @Test func keepsAPathOutsideHome() {
        #expect("/tmp/App".abbreviatingHome == "/tmp/App")
    }
}
