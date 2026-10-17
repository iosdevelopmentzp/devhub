import Foundation

@MainActor
final class RunState {
    var error: String?
    var view: ScriptView?
    var refresh: Set<RefreshTarget> = []
}

extension ActionRunner {
    func execute(_ action: CatalogAction, _ resolved: ResolvedAction, item: ActionItemContext, inputs: [String: String]) async {
        let startedAt = Date()
        let state = RunState()
        setResult(ActionResult(status: .running, startedAt: startedAt), for: action.id)
        defer {
            tasks[action.id] = nil
            if progress?.actionID == action.id {
                setProgress(nil)
            }
        }
        let context = contextBuilder.make(configDir: resolved.origin.directory, item: item, inputs: inputs)
        var status = ActionResult.Status.succeeded
        do {
            let exitCode = try await perform(resolved, context: context, state: state, action: action)
            await flushDirectives()
            if let message = state.error {
                status = .failed(message)
            } else if exitCode != 0 {
                status = .failed("Exited with code \(exitCode).")
            }
        } catch is CancellationError {
            await flushDirectives()
            status = .cancelled
        } catch {
            status = .failed(error.localizedDescription)
        }
        finish(action, resolved, status: status, state: state, startedAt: startedAt)
    }

    private func perform(_ resolved: ResolvedAction, context: ActionContext, state: RunState, action: CatalogAction) async throws -> Int32 {
        let config = resolved.config
        let placeholders = context.placeholders
        let folder = contextBuilder.workingFolder(config.cwd, context: context)
        switch config.run {
        case let .script(path):
            let executable = path.hasPrefix("/") ? path : resolved.origin.directory + "/" + path
            return try await stream(executable, [], folder: folder, context: context, state: state, action: action)
        case let .command(arguments):
            let expanded = arguments.map { PlaceholderExpander.expand($0, values: placeholders, encodesForURL: false) }
            guard let executable = expanded.first, executable.isEmpty == false else {
                throw ConfigFailure(message: "The command is empty.")
            }
            return try await stream(executable, Array(expanded.dropFirst()), folder: folder, context: context, state: state, action: action)
        case let .terminal(text):
            let command = PlaceholderExpander.expand(text, values: placeholders, encodesForURL: false)
            return await projectActions.runInTerminal(command, at: folder, title: config.title) ? 0 : 1
        case let .open(target):
            let expanded = PlaceholderExpander.expand(target, values: placeholders, encodesForURL: target.contains("://"))
            return await projectActions.openTarget(expanded, title: config.title) ? 0 : 1
        }
    }

    private func stream(_ executable: String, _ arguments: [String], folder: String, context: ActionContext, state: RunState, action: CatalogAction) async throws -> Int32 {
        let handler = lineHandler(state: state, action: action)
        return try await shell.stream(executable, arguments, cwd: folder, environment: context.environment, onLine: handler)
    }

    private func lineHandler(state: RunState, action: CatalogAction) -> @Sendable (String) -> Void {
        { [weak self] line in
            guard let self else { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.handle(line, state: state, action: action)
                }
            }
        }
    }

    private func flushDirectives() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    private func finish(_ action: CatalogAction, _ resolved: ResolvedAction, status: ActionResult.Status, state: RunState, startedAt: Date) {
        let finishedAt = Date()
        setResult(ActionResult(status: status, startedAt: startedAt, finishedAt: finishedAt, view: state.view), for: action.id)
        recordRun(of: action.id, at: finishedAt)
        switch status {
        case .succeeded:
            activity.log(action.title, detail: resolved.origin.fileName, outcome: .success)
            applyRefresh(Set(resolved.config.refresh ?? []).union(state.refresh))
        case let .failed(message):
            activity.log(action.title, detail: message, outcome: .failure)
            toaster.show("\(action.title) failed: \(message)", tint: .red)
            if state.error != nil {
                events.post(.commandFailed(message))
            }
        case .cancelled:
            activity.log(action.title, detail: "Cancelled", outcome: .info)
        case .running:
            break
        }
    }

    func applyRefresh(_ targets: Set<RefreshTarget>) {
        for target in targets {
            switch target {
            case .git:
                Task { await session.refresh() }
                events.post(.branchesChanged)
            case .worktrees: events.post(.worktreesChanged)
            case .simulators: events.post(.simulatorsChanged)
            case .scripts: Task { await config.reload() }
            case .logs: break
            }
        }
    }
}
