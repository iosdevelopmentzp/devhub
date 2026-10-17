import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockProjectDetectorTests {
    @Test func namesTheProjectAfterTheFolder() {
        let detector = MockProjectDetector()
        let folder = URL(fileURLWithPath: "/tmp/Projects/App")

        let project = detector.project(at: folder)

        #expect(project.name == "App")
        #expect(project.scheme == "App")
        #expect(project.bundleID == "")
        #expect(project.identity == nil)
        #expect(detector.isGitRepository(folder))
    }
}
