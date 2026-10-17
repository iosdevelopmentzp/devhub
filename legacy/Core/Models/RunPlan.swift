import Foundation

nonisolated struct RunPlan: Sendable {
    let mode: RunMode
    let simulator: SimulatorInfo
    let effective: EffectiveProject
    let scheme: String
    let configuration: String
    let source: BuildSource
    let fast: Bool
    let cleanInstall: Bool
    let profile: LaunchProfile?
    let projectPath: String
}

nonisolated struct BuildOutcome: Sendable {
    var exitCode: Int32 = 0
    var firstError: String?
    var appPath: String?
}

nonisolated struct BuildFolder: Sendable {
    let path: String
    let branch: String?
}
