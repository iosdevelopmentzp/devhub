import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct ScriptRowMapperTests {
    @Test func aRunnableScript() {
        var action = ConfigSample.action("script:hello", run: .script("scripts/hello.sh"), inputs: [ActionInput(key: "a", title: "A", type: .text)])
        action.config.subtitle = "Says hello"

        let model = ScriptRowMapper.model(for: action, isRunning: false, lastRun: nil, editor: "Xcode", isFavorite: false)

        #expect(model.title == "Script:Hello")
        #expect(model.subtitle == "Says hello")
        #expect(model.fileName == "script:hello.json")
        #expect(model.scriptPath == ConfigSample.directory + "/scripts/hello.sh")
        #expect(model.tags.map(\.text) == ["1 input", "project"])
        #expect(model.lastRunText == "never run")
        #expect(model.blockedTag == nil)
        #expect(model.iconTint == .purple)
        #expect(model.editTitle == "Edit in Xcode")
    }

    @Test func aScriptWithoutExecuteBitIsBlockedWithACommand() {
        let action = ConfigSample.action("x", run: .script("scripts/x.sh"), isExecutable: false)

        let model = ScriptRowMapper.model(for: action, isRunning: false, lastRun: Date(), editor: "Xcode", isFavorite: false)

        #expect(model.isRunnable == false)
        #expect(model.blockedTag?.tint == .orange)
        #expect(model.chmodCommand == "chmod +x \"\(ConfigSample.directory)/scripts/x.sh\"")
        #expect(model.lastRunText.hasPrefix("ran "))
    }

    @Test func aNonScriptActionHasNoPath() {
        #expect(ScriptRowMapper.model(for: ConfigSample.action("o", run: .open("https://example.com")), isRunning: true, lastRun: nil, editor: "Xcode", isFavorite: false).scriptPath == nil)
    }

    @Test func favoriteFlagIsPassedOn() {
        let action = ConfigSample.action("x", run: .script("scripts/x.sh"))

        #expect(ScriptRowMapper.model(for: action, isRunning: false, lastRun: nil, editor: "Xcode", isFavorite: true).isFavorite)
    }
}
