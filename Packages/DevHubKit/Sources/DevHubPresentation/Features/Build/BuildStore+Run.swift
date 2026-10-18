import AppKit
import DevHubDomain

extension BuildStore {
    func run(branch: String) {
        useSource(branch: branch)
        run()
    }

    func run(worktreeID: Worktree.ID) {
        useSource(worktreeID: worktreeID)
        run()
    }

    func run(on simulatorID: Simulator.ID) {
        selectTarget(id: simulatorID)
        run()
    }

    func showLog() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("DevHub-build.log")
        do {
            try log.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(url)
        } catch {
            activity.log("Could not write build log", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func events(for request: BuildRequest, prepared: PrepareBuildCheckoutUseCase.Prepared, simulator: Simulator) -> AsyncThrowingStream<BuildEvent, Error> {
        let project = config.resolved.project
        guard isCommandProject else { return buildAndRun.run(request) }
        let context = ActionContextPolicy.make(ActionContextInputs(
            projectPath: ProjectPath(session.selectedProject.path).expanded,
            projectName: session.selectedProject.name,
            checkoutPath: ProjectPath(prepared.path).expanded,
            branch: worktrees.worktree(atPath: prepared.path)?.branch ?? "",
            effective: effective,
            simulatorUDID: simulator.id,
            simulatorName: simulator.name,
            appPath: "",
            configDir: "",
            item: .none,
            inputs: [:],
            version: ""
        ))
        return commandRun.run(CommandRunRequest(
            buildCommand: project.build?.command,
            runCommand: project.run?.command,
            folder: ProjectPath(prepared.path).expanded,
            environment: context.environment,
            target: request
        ))
    }

    func logPrepared(_ prepared: PrepareBuildCheckoutUseCase.Prepared) {
        let name = prepared.worktreeName ?? prepared.path.abbreviatingHome
        if prepared.createdWorktree {
            activity.log("Created worktree", detail: "\(name) · \(prepared.path.abbreviatingHome)", outcome: .success)
        }
        if prepared.bootstrapped {
            activity.log("Bootstrapped \(name)", detail: "\(worktrees.gitSettings.worktrees.bootstrap ?? "The bootstrap script") finished", outcome: .success)
        }
    }

    func logCheckoutFailure(_ error: Error) {
        guard let error = error as? BuildSourceError else { return }
        switch error {
        case .worktreeNotCreated:
            break
        case .creationFailed(_, let message):
            activity.log("Could not create worktree", detail: message, outcome: .failure)
        case .bootstrapFailed(let name, let path, let createdWorktree, let message):
            if createdWorktree {
                activity.log("Created worktree", detail: "\(name) · \(path.abbreviatingHome)", outcome: .success)
            }
            activity.log("Bootstrap failed: \(name)", detail: "\(message) Full output in the Output panel.", outcome: .failure)
            events.post(.worktreeCheckoutPrepared)
        }
    }

    func ensureAccessibility() -> Bool {
        guard attacher.isTrusted == false else { return true }
        attacher.requestTrust()
        activity.log("Allow DevHub in Accessibility", detail: "System Settings → Privacy & Security → Accessibility, then try again", outcome: .failure)
        return false
    }
}
