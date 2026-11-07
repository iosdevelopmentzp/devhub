import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct SupportBundleStoreTests {
    private let harness = StoreHarness()

    private var store: SupportBundleStore {
        harness.supportBundle
    }

    private var ownCrash: CrashReport {
        var report = MockData.crashReport
        report.processName = "DevHub"
        report.simulatorID = nil
        report.messages = ["\(ProjectSample.path)/Sources/HomeView.swift:42: Fatal error"]
        return report
    }

    private func script() {
        harness.spies.crashes.ownReportsResult = .success([ownCrash])
        harness.spies.redactionWords.wordsResult = .success([.word("Secretish")])
        let id = UUID()
        harness.commandLog.handle(CommandEvent(id: id, payload: .started(command: "git -C \(ProjectSample.path) fetch https://github.com/example/app.git", cwd: ProjectSample.path, kind: .read, operationID: nil)))
        harness.commandLog.handle(CommandEvent(id: id, payload: .output(["Secretish from sam@example.org at 10.0.0.12", "scheme App, bundle com.example.app"])))
        harness.commandLog.handle(CommandEvent(id: id, payload: .finished(exitCode: 0, error: nil)))
        harness.activity.log("Build failed: App", detail: "\(ProjectSample.path)/App.xcodeproj", outcome: .failure)
    }

    @Test func theBundleHasEverySectionAndIsRedacted() async {
        script()

        let text = await store.text()

        #expect(text.hasPrefix("DevHub support bundle\n"))
        #expect(text.contains("DevHub: 1.0\n"))
        #expect(text.contains("macOS: Version 26.4\n"))
        #expect(text.contains("## Settings\nWindow: panel"))
        #expect(text.contains("Scheme: <scheme>\n"))
        #expect(text.contains("Bundle: <bundle>\n"))
        #expect(text.contains("## Tools\n"))
        #expect(text.contains("## CI\nProvider: none\n"))
        #expect(text.contains("## Last DevHub crash\nProcess: DevHub 1.5.2\n"))
        #expect(text.contains("Message: <project>/Sources/HomeView.swift:42: Fatal error"))
        #expect(text.contains("failed Build failed: <scheme> — <project>/<scheme>.xcodeproj"))
        #expect(text.contains("$ git -C <project> fetch <url>"))
        #expect(text.contains("<redacted> from <email> at <ip>"))
        #expect(text.contains("scheme <scheme>, bundle <bundle>"))
        #expect(text.contains(ProjectSample.path) == false)
        #expect(text.contains("Secretish") == false)
        #expect(text.contains("github.com") == false)
        #expect(harness.spies.crashes.calls.contains(.ownReports(processName: "DevHub", bundleID: "com.example.app", since: Date(timeIntervalSince1970: 1_800_000_000 - SupportBundleStore.crashAge))))
    }

    @Test func copyPutsTheTextOnThePasteboardAndLogsIt() async {
        script()

        await store.copy()

        #expect(harness.copied.first?.hasPrefix("DevHub support bundle\n") == true)
        #expect(harness.lastActivity?.title == "Support bundle copied")
    }

    @Test func saveWritesTheChosenFile() async {
        script()

        await store.save()

        #expect(harness.requestedFileNames.first?.hasPrefix("DevHub support bundle ") == true)
        guard case .write(let text, let path)? = harness.spies.textFiles.calls.last else {
            Issue.record("Expected a write")
            return
        }
        #expect(path == "/tmp/DevHubTests/ci-diagnostics.txt")
        #expect(text.hasPrefix("DevHub support bundle\n"))
        #expect(harness.lastActivity?.title == "Support bundle saved")
    }

    @Test func aCancelledSaveWritesNothing() async {
        harness.saveTarget = nil

        await store.save()

        #expect(harness.spies.textFiles.calls.isEmpty)
    }
}
