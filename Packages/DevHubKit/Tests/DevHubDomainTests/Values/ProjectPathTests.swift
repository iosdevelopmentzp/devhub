import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ProjectPathTests {
    private let home = NSHomeDirectory()

    @Test func expandedReplacesTheTilde() {
        #expect(ProjectPath("~/Projects/App").expanded == home + "/Projects/App")
    }

    @Test func expandedKeepsAnAbsolutePath() {
        #expect(ProjectPath("/tmp/App").expanded == "/tmp/App")
    }

    @Test func abbreviatedShortensTheHomeFolder() {
        #expect(ProjectPath(home + "/Projects/App").abbreviated == "~/Projects/App")
    }

    @Test func abbreviatedKeepsAPathOutsideHome() {
        #expect(ProjectPath("/tmp/App").abbreviated == "/tmp/App")
    }

    @Test func urlIsAFileURLOfTheExpandedPath() {
        let url = ProjectPath("~/Projects/App").url

        #expect(url.isFileURL)
        #expect(url.path == home + "/Projects/App")
    }
}
