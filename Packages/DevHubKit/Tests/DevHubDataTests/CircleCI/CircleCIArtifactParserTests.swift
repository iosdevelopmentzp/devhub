import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIArtifactParserTests {
    @Test func artifactsWithAPathAreKept() throws {
        let artifacts = try CircleCIArtifactParser.artifacts(from: CircleCIFixture.artifacts)

        #expect(artifacts.map(\.path) == ["test-results/junit.xml", "screenshots/LoginTests.png"])
        #expect(artifacts.first?.url?.absoluteString == "https://app.circleci.example.com/artifacts/0/test-results/junit.xml")
        #expect(artifacts.last?.fileName == "LoginTests.png")
    }

    @Test func aPageObjectAndAnEmptyListAreRead() throws {
        #expect(try CircleCIArtifactParser.artifacts(from: Data(#"{"items":[{"path":"a.txt"}]}"#.utf8)).map(\.path) == ["a.txt"])
        #expect(try CircleCIArtifactParser.artifacts(from: Data("[]".utf8)).isEmpty)
    }
}
