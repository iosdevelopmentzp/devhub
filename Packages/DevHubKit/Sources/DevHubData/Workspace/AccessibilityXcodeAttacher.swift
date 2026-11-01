import Foundation
import ApplicationServices
import DevHubDomain

struct AccessibilityXcodeAttacher: XcodeAttaching {
    let shell: ShellRunner

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestTrust() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func attach(pid: Int32, simulatorUDID: String, projectPath: String, container preferred: String?) async throws {
        guard isTrusted else {
            requestTrust()
            throw XcodeAttachError.accessibilityNotGranted
        }
        guard let container = try? XcodeContainer.locate(in: projectPath, preferred: preferred) else {
            throw XcodeAttachError.noProject(projectPath)
        }
        let hadWindows = await windowCount() > 0
        _ = try await shell.run("open", ["-a", shell.developerDir.xcodeAppName(), container.url.path], cwd: nil)
        if hadWindows == false {
            try await waitForWindow()
            try await Task.sleep(for: .seconds(6))
        } else {
            try await Task.sleep(for: .seconds(1.5))
        }

        await selectRunDestination(udid: simulatorUDID, documentPath: container.url.path)

        let script = """
        tell application "System Events" to tell process "Xcode"
            set frontmost to true
            delay 0.5
            click menu item "Attach to Process by PID or Name…" of menu 1 of menu bar item "Debug" of menu bar 1
            delay 1.5
            set value of text field 1 of sheet 1 of window 1 to "\(pid)"
            delay 0.3
            click button "Attach" of sheet 1 of window 1
        end tell
        """
        let result = try await shell.run("osascript", ["-e", script], cwd: nil)
        guard result.exitCode == 0 else { throw XcodeAttachError.script(result.failureMessage) }

        for _ in 0..<25 {
            try await Task.sleep(for: .seconds(1))
            guard await isStopped(pid) else { return }
        }
        throw XcodeAttachError.stillStopped(pid)
    }

    private func selectRunDestination(udid: String, documentPath: String) async {
        let script = """
        tell application "Xcode"
            set workspaceDocument to first workspace document whose path is "\(documentPath)"
            repeat with destination in run destinations of workspaceDocument
                try
                    if device identifier of (device of destination) is "\(udid)" then
                        set active run destination of workspaceDocument to destination
                        exit repeat
                    end if
                end try
            end repeat
        end tell
        """
        _ = try? await shell.run("osascript", ["-e", script], cwd: nil)
        try? await Task.sleep(for: .milliseconds(500))
    }

    private func windowCount() async -> Int {
        let script = """
        tell application "System Events"
            if exists process "Xcode" then return count windows of process "Xcode"
        end tell
        return 0
        """
        let result = try? await shell.run("osascript", ["-e", script], cwd: nil)
        return Int(result?.stdout.trimmed ?? "") ?? 0
    }

    private func waitForWindow() async throws {
        let deadline = Date().addingTimeInterval(150)
        while Date() < deadline {
            if await windowCount() > 0 { return }
            try await Task.sleep(for: .seconds(3))
        }
        throw XcodeAttachError.xcodeDidNotOpen
    }

    private func isStopped(_ pid: Int32) async -> Bool {
        guard let result = try? await shell.run("ps", ["-o", "stat=", "-p", "\(pid)"], cwd: nil) else { return false }
        return result.stdout.trimmed.hasPrefix("T")
    }
}
