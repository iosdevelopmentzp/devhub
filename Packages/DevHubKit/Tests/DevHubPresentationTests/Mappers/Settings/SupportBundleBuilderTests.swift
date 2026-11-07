import Foundation
import Testing
import DevHubDomain
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct SupportBundleBuilderTests {
    private func facts(events: [ActivityEvent] = [], commands: [CommandLog.Entry] = [], tools: [ToolStatus] = [], issues: [ConfigIssue] = []) -> SupportBundleBuilder.Facts {
        SupportBundleBuilder.Facts(
            appVersion: "1.0",
            systemVersion: "Version 26.4",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            settings: AppSettings(mutedNotifications: [.tests, .build]),
            projectKind: "xcode",
            scheme: "ExampleApp",
            bundleID: "com.example.app",
            configIssues: issues,
            tools: tools,
            ciProvider: nil,
            ciSlug: nil,
            ciTool: "not used",
            crash: nil,
            events: events,
            commands: commands
        )
    }

    private func entry(_ index: Int, lines: Int = 1) -> CommandLog.Entry {
        CommandLog.Entry(id: UUID(), command: "git status \(index)", cwd: nil, kind: .read, operationID: nil, startedAt: Date(timeIntervalSince1970: 1_000), finishedAt: Date(timeIntervalSince1970: 1_001), exitCode: 0, error: nil, lines: (0..<lines).map { "line \($0)" }, droppedLines: 0)
    }

    @Test func theSettingsToolsAndProblemsAreListed() {
        let git = DoctorTool(name: "git", versionArguments: ["--version"], purpose: "", installCommand: "")
        let glab = DoctorTool(name: "glab", versionArguments: ["--version"], purpose: "", installCommand: "")
        let text = SupportBundleBuilder.text(facts(
            tools: [ToolStatus(tool: git, path: "/usr/bin/git", version: "2.50"), ToolStatus(tool: glab, path: nil, version: nil)],
            issues: [ConfigIssue(layer: .project, fileName: "project.json", message: "Unknown key")]
        ))

        #expect(text.contains("Notifications while the panel is closed: on, muted: build, tests\n"))
        #expect(text.contains("Review reminder: 4 h, remember reviews: on\n"))
        #expect(text.contains("git: 2.50 at /usr/bin/git\nglab: missing\n"))
        #expect(text.contains("Config problems:\n- project project.json: Unknown key\n"))
        #expect(text.contains("## Last DevHub crash\nnone\n"))
        #expect(text.contains("## Recent (last 0)\nnone\n"))
    }

    @Test func onlyTheLastHundredCommandsWithHeadAndTailAreKept() {
        let text = SupportBundleBuilder.text(facts(commands: (0..<105).map { entry($0) } + [entry(200, lines: 50)]))

        #expect(text.contains("## Commands (last 100)\n"))
        #expect(text.contains("$ git status 5\n") == false)
        #expect(text.contains("$ git status 6\n"))
        #expect(text.contains("(10 lines left out)"))
    }

    @Test func theCrashLinesNameTheExceptionAndTheFrames() {
        let lines = AppCrashText.lines(MockData.crashReport)

        #expect(lines.first == "Process: ExampleApp 1.5.2")
        #expect(lines.contains("Exception: EXC_BREAKPOINT (SIGTRAP)"))
        #expect(lines.contains("1 ExampleApp.debug.dylib ProfileViewModel.load() (ProfileViewModel.swift:42)"))
    }
}
