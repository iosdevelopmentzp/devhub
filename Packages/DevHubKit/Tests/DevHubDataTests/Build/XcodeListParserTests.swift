import Testing
@testable import DevHubData

@Suite struct XcodeListParserTests {

    @Test func projectGivesSchemesThenTargetsWithoutRepeats() {
        let output = """
        {
          "project" : {
            "configurations" : ["Debug", "Release"],
            "name" : "ExampleApp",
            "schemes" : ["ExampleApp", "ExampleApp Staging"],
            "targets" : ["ExampleApp", "ExampleWidget", "ExampleAppTests"]
          }
        }
        """

        #expect(XcodeListParser.names(from: output) == ["ExampleApp", "ExampleApp Staging", "ExampleWidget", "ExampleAppTests"])
    }

    @Test func workspaceGivesItsSchemes() {
        let output = #"{"workspace": {"name": "ExampleApp", "schemes": ["ExampleApp", "Pods-ExampleApp"]}}"#

        #expect(XcodeListParser.names(from: output) == ["ExampleApp", "Pods-ExampleApp"])
    }

    @Test func textBeforeTheJSONIsSkipped() {
        let output = "Command line invocation:\n    xcodebuild -list -json\n{\"project\": {\"schemes\": [\"ExampleApp\"]}}"

        #expect(XcodeListParser.names(from: output) == ["ExampleApp"])
    }

    @Test func brokenOutputGivesNoNames() {
        #expect(XcodeListParser.names(from: "").isEmpty)
        #expect(XcodeListParser.names(from: "{ not json").isEmpty)
    }
}
