import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIArtifactTests {
    @Test func theFileNameIsTheLastPathPart() {
        let artifact = CIArtifact(path: "test-results/junit.xml", url: nil)

        #expect(artifact.fileName == "junit.xml")
        #expect(artifact.id == "test-results/junit.xml")
    }
}
