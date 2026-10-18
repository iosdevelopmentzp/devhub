import Testing
@testable import DevHubData

@Suite struct WorkspaceYAMLParserTests {
    @Test func readsTopLevelKeysAndUnquotesValues() {
        let text = """
        id: 1a2b
        cwd: /Users/dev/Projects/App
        # a comment
        branch: "feature/x"
        summary: 'It''s done'
        name: "Say \\"hi\\""
          nested: ignored
        empty:
        """

        let values = WorkspaceYAMLParser.parse(text)

        #expect(values == [
            "id": "1a2b",
            "cwd": "/Users/dev/Projects/App",
            "branch": "feature/x",
            "summary": "It's done",
            "name": #"Say "hi""#,
            "empty": ""
        ])
    }
}
