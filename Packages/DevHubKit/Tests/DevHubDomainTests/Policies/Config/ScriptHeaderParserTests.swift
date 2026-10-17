import Testing
@testable import DevHubDomain

@Suite struct ScriptHeaderParserTests {
    @Test func readsEveryHeaderField() {
        let result = ScriptHeaderParser.parse(ConfigFixture.header, relativePath: "scripts/regenerate.sh")

        #expect(result.hasHeader)
        #expect(result.action.id == "script:regenerate")
        #expect(result.action.title == "Regenerate")
        #expect(result.action.subtitle == "Runs the generator")
        #expect(result.action.tint == .purple)
        #expect(result.action.placements == [.homeScripts, .gitPills])
        #expect(result.action.run == .script("scripts/regenerate.sh"))
        #expect(result.action.refresh == [.git])
    }

    @Test func inputsTakeOptionsOrADefault() {
        let inputs = ScriptHeaderParser.parse(ConfigFixture.header, relativePath: "scripts/regenerate.sh").action.inputs ?? []

        #expect(inputs.map(\.key) == ["target", "verbose"])
        #expect(inputs.first?.options?.map(\.value) == ["app", "widget"])
        #expect(inputs.first?.defaultValue == "app")
        #expect(inputs.last?.type == .toggle)
        #expect(inputs.last?.defaultValue == "true")
    }

    @Test func unknownKeysAndTargetsAreProblems() {
        let problems = ScriptHeaderParser.parse(ConfigFixture.header, relativePath: "scripts/regenerate.sh").problems

        #expect(problems == ["refresh \"nothing\" is not a known store.", "unknown header key \"colour\"."])
    }

    @Test func aScriptWithoutHeaderUsesTheFileName() {
        let result = ScriptHeaderParser.parse("#!/bin/sh\necho hi", relativePath: "scripts/hello.sh")

        #expect(result.hasHeader == false)
        #expect(result.action.title == "hello")
        #expect(ScriptHeaderParser.hasShebang("#!/bin/sh"))
    }

    @Test func onlyTheFirstLinesAreRead() {
        let text = String(repeating: "echo\n", count: ScriptHeaderParser.maxLines) + "# devhub: title = Late"

        #expect(ScriptHeaderParser.parse(text, relativePath: "late.sh").hasHeader == false)
    }

    @Test func aBadInputIsAProblem() {
        let result = ScriptHeaderParser.parse("# devhub: input = only, two", relativePath: "x.sh")

        #expect(result.problems.count == 1)
        #expect(result.action.inputs == nil)
    }
}
