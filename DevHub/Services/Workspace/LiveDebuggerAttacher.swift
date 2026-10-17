import ApplicationServices
import Foundation

nonisolated struct LiveDebuggerAttacher: DebuggerAttaching {
    static let coldStartLimit = 150
    static let attachLimit = 25

    let shell: ShellRunner

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func attach(_ request: AttachRequest, onStep: @escaping @Sendable (String) -> Void) async throws {
        onStep("Opening Xcode")
        let wasRunning = await isXcodeRunning()
        try await run("open", ["-a", "Xcode", request.container])
        try await waitForWindow(coldStart: wasRunning == false, onStep: onStep)
        onStep("Choosing the run destination")
        try await selectDestination(request)
        onStep("Attaching to \(request.processID)")
        try await clickAttach(processID: request.processID)
        try await waitUntilRunning(request.processID)
    }

    private func isXcodeRunning() async -> Bool {
        guard let result = try? await shell.run("pgrep", ["-x", "Xcode"], cwd: nil) else { return false }
        return result.exitCode == 0
    }

    private func waitForWindow(coldStart: Bool, onStep: @escaping @Sendable (String) -> Void) async throws {
        let limit = coldStart ? Self.coldStartLimit : 20
        for second in stride(from: 0, to: limit, by: 2) {
            try Task.checkCancellation()
            let output = try await script("tell application \"System Events\" to count windows of process \"Xcode\"")
            if (Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0 {
                try await Task.sleep(for: .seconds(coldStart ? 6 : 1.5))
                return
            }
            onStep("Waiting for Xcode (\(second) s)")
            try await Task.sleep(for: .seconds(2))
        }
        throw AttachFailure(message: "Xcode did not open a window in time.")
    }

    private func selectDestination(_ request: AttachRequest) async throws {
        let source = """
        tell application "Xcode"
            set targetDocument to first workspace document
            repeat with candidate in run destinations of targetDocument
                try
                    if device identifier of (device of candidate) is "\(request.simulatorID)" then
                        set active run destination of targetDocument to candidate
                        return "selected"
                    end if
                end try
            end repeat
            return "missing"
        end tell
        """
        _ = try await script(source)
    }

    private func clickAttach(processID: Int) async throws {
        let source = """
        tell application "System Events"
            tell process "Xcode"
                set frontmost to true
                click menu item "Attach to Process by PID or Name…" of menu 1 of menu bar item "Debug" of menu bar 1
                repeat 20 times
                    if exists sheet 1 of window 1 then exit repeat
                    delay 0.5
                end repeat
                set value of text field 1 of sheet 1 of window 1 to "\(processID)"
                delay 0.4
                click button "Attach" of sheet 1 of window 1
            end tell
        end tell
        """
        _ = try await script(source)
    }

    private func waitUntilRunning(_ processID: Int) async throws {
        for _ in 0..<Self.attachLimit {
            try Task.checkCancellation()
            let result = try await shell.run("ps", ["-o", "stat=", "-p", String(processID)], cwd: nil)
            let state = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if state.isEmpty == false, state.hasPrefix("T") == false {
                return
            }
            try await Task.sleep(for: .seconds(1))
        }
        throw AttachFailure(message: "The app is still waiting for the debugger. \(AttachAdvice.manualSteps(processID: processID))")
    }

    private func script(_ source: String) async throws -> String {
        let path = NSTemporaryDirectory() + "devhub-\(UUID().uuidString).applescript"
        try source.write(toFile: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: path) }
        let result = try await shell.run("osascript", [path], cwd: nil)
        guard result.exitCode == 0 else {
            throw AttachFailure(message: "Xcode could not be controlled: \(result.failureMessage)")
        }
        return result.stdout
    }

    private func run(_ executable: String, _ arguments: [String]) async throws {
        let result = try await shell.run(executable, arguments, cwd: nil)
        guard result.exitCode == 0 else {
            throw AttachFailure(message: result.failureMessage)
        }
    }
}
