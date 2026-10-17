import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ScriptRowMapperTests {
    let script = ScriptAction(
        id: "reset-simulators",
        title: "Reset simulators",
        subtitle: "Erase every shutdown simulator",
        fileName: "reset-simulators.sh",
        systemImage: "arrow.counterclockwise",
        lastRun: nil
    )

    @Test func neverRunScript() {
        let model = ScriptRowMapper.model(for: script, isRunning: false, editor: "Xcode")

        #expect(model.id == "reset-simulators")
        #expect(model.title == "Reset simulators")
        #expect(model.subtitle == "Erase every shutdown simulator")
        #expect(model.fileName == "reset-simulators.sh")
        #expect(model.icon == "arrow.counterclockwise")
        #expect(model.iconTint == .purple)
        #expect(model.lastRunText == "never run")
        #expect(model.isRunning == false)
        #expect(model.editTitle == "Edit in Xcode")
    }

    @Test func runningScriptWithLastRun() {
        var ran = script
        ran.lastRun = Date(timeIntervalSinceNow: -3_600)

        let model = ScriptRowMapper.model(for: ran, isRunning: true, editor: "Cursor")

        #expect(model.lastRunText.hasPrefix("ran "))
        #expect(model.isRunning)
        #expect(model.editTitle == "Edit in Cursor")
    }
}
