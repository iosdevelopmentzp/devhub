import Testing
@testable import DevHubPresentation

@Suite struct JSONPrettyPrinterTests {
    @Test func indentsAnObjectWithSortedKeysAndPlainSlashes() {
        #expect(JSONPrettyPrinter.format(#" {"b":[1,2],"a":"x/y"} "#) == "{\n  \"a\" : \"x/y\",\n  \"b\" : [\n    1,\n    2\n  ]\n}")
    }

    @Test func indentsAnArray() {
        #expect(JSONPrettyPrinter.format("[1]") == "[\n  1\n]")
    }

    @Test(arguments: ["", "plain text", "<html></html>", "{broken", "42", #""string""#])
    func leavesOtherTextAsItIs(text: String) {
        #expect(JSONPrettyPrinter.format(text) == text)
    }
}
