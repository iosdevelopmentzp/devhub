import Foundation
import DevHubDomain
import DevHubMocks
import DevHubUI

extension PresentationAssembly {

    package static func preview() -> PresentationAssembly {
        let ports = Ports.mock()
        let assembly = PresentationAssembly(
            ports: ports,
            useCases: UseCases(ports: ports),
            store: InMemoryKeyValueStore(),
            commandLog: CommandLog(),
            projects: MockData.projects,
            selectedProjectID: nil,
            settings: AppSettings(),
            recentEvents: MockData.recentEvents
        )
        assembly.worktrees.worktrees = MockData.worktrees
        assembly.worktrees.derivedDataSizes = MockData.derivedDataSizes
        assembly.simulators.groups = MockData.simulatorGroups
        assembly.identity.apps = MockData.installedApps
        assembly.usage.usage = MockData.usage
        assembly.usage.copilot = MockData.copilotUsage
        assembly.ciHistory.remember(MockData.ciPreviousWorkflow, failedTests: MockData.ciPreviousFailedTests, for: 1842)
        seedOperations(of: assembly)
        return assembly
    }

    private static func seedOperations(of assembly: PresentationAssembly) {
        let push = assembly.operations.start("Push feature/ABC-123-short-title", at: .git, retry: {}, stop: nil)
        let fetchCommand = UUID()
        let pushCommand = UUID()
        assembly.commandLog.handle(CommandEvent(id: fetchCommand, payload: .started(command: "git fetch origin", cwd: "~/Projects/example-app", kind: .action, operationID: push)))
        assembly.commandLog.handle(CommandEvent(id: fetchCommand, payload: .finished(exitCode: 0, error: nil)))
        assembly.commandLog.handle(CommandEvent(id: pushCommand, payload: .started(command: "git push origin feature/ABC-123-short-title", cwd: "~/Projects/example-app", kind: .action, operationID: push)))
        assembly.commandLog.handle(CommandEvent(id: pushCommand, payload: .output([
            "To github.com:example/app.git",
            " ! [rejected]        feature/ABC-123-short-title -> feature/ABC-123-short-title (fetch first)",
            "error: failed to push some refs to 'github.com:example/app.git'",
            "hint: Updates were rejected because the remote contains work that you do not",
            "hint: have locally. Integrate the remote changes before pushing again.",
        ])))
        assembly.commandLog.handle(CommandEvent(id: pushCommand, payload: .finished(exitCode: 1, error: nil)))
        assembly.operations.fail(push, message: "The remote has commits that you do not have. Pull first, then push again.")
        let script = assembly.operations.start("Regenerate Project", at: .action("regenerate"), retry: nil, stop: {})
        assembly.commandLog.handle(CommandEvent(id: UUID(), payload: .started(command: "./scripts/regenerate.sh", cwd: "~/Projects/example-app", kind: .action, operationID: script)))
        assembly.operations.setProgress(of: script, text: "Step 2 of 3", fraction: 0.6)
    }
}
