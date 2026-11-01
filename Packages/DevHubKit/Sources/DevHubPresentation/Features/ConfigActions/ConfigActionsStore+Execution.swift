import Foundation
import DevHubDomain
import DevHubUI

extension ConfigActionsStore {
    func execute(_ action: ResolvedAction, item: ActionItemContext, inputs: [String: String]) async {
        let startedAt = runs[action.id]?.startedAt ?? Date()
        var outcome = ConfigActionOutcome()
        let context = await makeContext(action, item: item, inputs: inputs)
        var status = ConfigActionRun.Status.succeeded
        do {
            let exitCode = try await perform(action, context: context, outcome: &outcome)
            if let message = outcome.error {
                status = .failed(message)
            } else if exitCode != 0 {
                status = .failed("Exited with code \(exitCode).")
            }
        } catch is CancellationError {
            status = .cancelled
        } catch {
            status = Task.isCancelled ? .cancelled : .failed(error.localizedDescription)
        }
        tasks[action.id] = nil
        finish(action, item: item, status: status, outcome: outcome, startedAt: startedAt)
    }

    private func makeContext(_ action: ResolvedAction, item: ActionItemContext, inputs: [String: String]) async -> ActionContext {
        let project = session.selectedProject
        let target = build.target
        let udid = item.simulatorUDID ?? target?.id ?? ""
        return ActionContextPolicy.make(ActionContextInputs(
            projectPath: ProjectPath(project.path).expanded,
            projectName: project.name,
            checkoutPath: ProjectPath(checkout.checkoutPath.isEmpty ? project.path : checkout.checkoutPath).expanded,
            branch: currentBranch ?? "",
            effective: effective,
            simulatorUDID: target?.id ?? "",
            simulatorName: target?.name ?? "",
            appPath: build.lastBuiltAppPath() ?? "",
            configDir: action.origin.directory,
            item: item,
            inputs: inputs,
            version: appVersion,
            profileID: target.flatMap { build.profile(for: $0.id) }?.id ?? "",
            hostKind: codeHosts.kind,
            containers: await launcher.containers(udid: udid, bundleID: item.bundleID ?? effective.bundleID ?? ""),
            simulatorState: simulators.simulator(id: udid)?.state
        ))
    }

    private func perform(_ action: ResolvedAction, context: ActionContext, outcome: inout ConfigActionOutcome) async throws -> Int32 {
        let config = action.config
        let placeholders = context.placeholders
        let folder = ActionContextPolicy.workingFolder(config.cwd, context: context, home: home)
        switch config.run {
        case let .script(path):
            let executable = path.hasPrefix("/") ? path : ProjectPath(action.origin.directory).expanded + "/" + path
            return try await stream(ScriptRunRequest(executable: executable, arguments: [], cwd: folder, environment: context.environment), action: action, outcome: &outcome)
        case let .command(arguments):
            let expanded = arguments.map { PlaceholderExpander.expand($0, values: placeholders, encodesForURL: false) }
            guard let executable = expanded.first, executable.isEmpty == false else {
                throw ConfigError.emptyCommand
            }
            return try await stream(ScriptRunRequest(executable: executable, arguments: Array(expanded.dropFirst()), cwd: folder, environment: context.environment), action: action, outcome: &outcome)
        case let .terminal(text):
            workspace.runInTerminal(PlaceholderExpander.expand(text, values: placeholders, encodesForURL: false), at: folder, title: config.title)
            return 0
        case let .open(target):
            let expanded = PlaceholderExpander.expand(target, values: placeholders, encodesForURL: target.contains("://"))
            return workspace.openTarget(expanded, relativeTo: folder) ? 0 : 1
        }
    }

    private func stream(_ request: ScriptRunRequest, action: ResolvedAction, outcome: inout ConfigActionOutcome) async throws -> Int32 {
        var exitCode: Int32 = 0
        for try await event in scripts.run(request) {
            switch event {
            case let .output(line):
                handle(line, action: action, outcome: &outcome)
            case let .exited(code):
                exitCode = code
            }
        }
        try Task.checkCancellation()
        return exitCode
    }

    private func finishOperation(of id: String, status: ConfigActionRun.Status) {
        guard let operationID = operationIDs[id] else { return }
        switch status {
        case .succeeded:
            operations.succeed(operationID)
        case let .failed(message):
            operations.fail(operationID, message: message)
        case .cancelled:
            operations.cancel(operationID)
        case .running:
            break
        }
    }

    private func finish(_ action: ResolvedAction, item: ActionItemContext, status: ConfigActionRun.Status, outcome: ConfigActionOutcome, startedAt: Date) {
        let finishedAt = Date()
        let title = action.config.title
        setRun(ConfigActionRun(status: status, startedAt: startedAt, finishedAt: finishedAt, view: outcome.view), for: action.id)
        finishOperation(of: action.id, status: status)
        recordRun(of: action.id, at: finishedAt)
        var refresh = Set(item.refresh)
        switch status {
        case .succeeded:
            activity.log(title, detail: action.origin.fileName, outcome: .success)
            refresh.formUnion(action.config.refresh ?? [])
            refresh.formUnion(outcome.refresh)
        case let .failed(message):
            activity.log(title, detail: message, outcome: .failure)
            toaster.show("\(title) failed: \(message)")
            if outcome.error != nil {
                events.post(.commandFailed)
            }
        case .cancelled:
            activity.log(title, detail: "Cancelled", outcome: .info)
        case .running:
            break
        }
        for target in refresh {
            events.post(.refreshRequested(target))
        }
    }
}
