import Foundation
import DevHubDomain

struct SimulatorScriptEnvironment {
    let config: ConfigStore
    let session: ProjectSession
    let build: any BuildLookup
    let codeHosts: any CodeHostLookup
    let launcher: any AppLaunchRepository

    func environment(for simulator: Simulator) async -> [String: String] {
        let project = session.selectedProject
        let path = ProjectPath(project.path).expanded
        let effective = config.effective(detectedSchemes: build.schemeOptions, detectedBaseBranch: nil)
        let containers = await launcher.containers(udid: simulator.id, bundleID: effective.bundleID ?? "")
        return ActionContextPolicy.make(ActionContextInputs(
            projectPath: path,
            projectName: project.name,
            checkoutPath: path,
            branch: "",
            effective: effective,
            simulatorUDID: simulator.id,
            simulatorName: simulator.name,
            appPath: build.lastBuiltAppPath(isPhysicalDevice: simulator.isPhysical) ?? "",
            configDir: "",
            item: ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name, rowID: simulator.id),
            inputs: [:],
            version: "",
            profileID: build.profile(for: simulator.id)?.id ?? "",
            hostKind: codeHosts.kind,
            containers: containers,
            simulatorState: simulator.state,
            isPhysicalDevice: simulator.isPhysical
        )).environment
    }
}
