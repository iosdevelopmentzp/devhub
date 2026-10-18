import Foundation
import DevHubDomain
import DevHubUI

extension BuildStore {
    var isRunning: Bool {
        state.isRunning
    }

    var schemeOptions: [String] {
        let visible = effective.schemes
        return visible.isEmpty ? [state.scheme] : visible
    }

    var configurationOptions: [String] {
        var options = ["Debug", "Release"]
        for extra in [effective.configuration, state.configuration] where options.contains(extra) == false {
            options.append(extra)
        }
        return options
    }

    var effective: EffectiveProject {
        config.effective(detectedSchemes: schemes, detectedBaseBranch: worktrees.baseBranch)
    }

    var container: String? {
        config.resolved.project.xcode?.container
    }

    var selectedScheme: String {
        state.scheme
    }

    var selectedConfiguration: String {
        state.configuration
    }

    var target: Simulator? {
        if let id = state.targetSimulatorID, let simulator = simulators.simulator(id: id) {
            return simulator
        }
        return simulators.all.first { $0.state == .booted } ?? simulators.all.first
    }

    func isTarget(_ id: Simulator.ID) -> Bool {
        target?.id == id
    }

    func willCleanInstall(on id: Simulator.ID) -> Bool {
        state.cleanInstall || profile?.cleanInstall == true || identity.needsCleanInstall(id: id)
    }

    var profiles: [LaunchProfile] {
        config.resolved.project.launch?.profiles ?? []
    }

    var profile: LaunchProfile? {
        profiles.first { $0.id == state.profileID } ?? profiles.first
    }

    func profile(for id: Simulator.ID) -> LaunchProfile? {
        guard id != state.targetSimulatorID else { return profile }
        let saved = savedProfileID(for: id)
        return profiles.first { $0.id == saved } ?? profiles.first
    }

    func launchPlan(for id: Simulator.ID) -> LaunchPlan {
        LaunchPlan(
            profile: profile(for: id),
            identityConfig: identity.identityConfig,
            identity: identity.settings(for: id).desiredIdentity,
            baseURLVariable: config.config.network?.baseURLVariable
        )
    }

    var sourceWorktreeID: Worktree.ID? {
        sourceResolution.worktreeID
    }

    var sourcePath: String {
        sourceResolution.path
    }

    var sourceLabel: String {
        sourceResolution.label
    }

    var isCommandProject: Bool {
        effective.kind == .command
    }

    var commandsSummary: String? {
        guard isCommandProject else { return nil }
        let project = config.resolved.project
        let commands = [project.build?.command, project.run?.command].compactMap { $0 }
        return commands.isEmpty ? "No build.command or run.command" : commands.joined(separator: " → ")
    }

    func lastBuiltAppPath() -> String? {
        repository.lastBuiltAppPath(projectPath: sourcePath, container: container, scheme: state.scheme, configuration: state.configuration)
    }

    var sourceResolution: BuildSourceResolver.BuildSourceResolution {
        BuildSourceResolver.resolve(
            source: source,
            worktrees: worktrees.worktrees,
            mainCheckoutPath: worktrees.mainCheckoutPath,
            projectName: session.selectedProject.name,
            remote: worktrees.gitSettings.remote
        )
    }
}
