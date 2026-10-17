import Testing
@testable import DevHubDomain

@Suite struct GitCommitFileTests {
    @Test func splitsThePathIntoNameAndFolder() {
        let file = GitCommitFile(path: "ExampleApp/Call/CallView.swift", originalPath: nil, kind: .modified)

        #expect(file.id == "ExampleApp/Call/CallView.swift")
        #expect(file.fileName == "CallView.swift")
        #expect(file.folder == "ExampleApp/Call")
    }
}
