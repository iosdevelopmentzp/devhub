import Foundation

nonisolated enum BuildSource: Codable, Hashable, Sendable {
    case main
    case worktree(String)
    case branch(String)
}

nonisolated struct RunOptions: Codable, Hashable, Sendable {
    var scheme: String?
    var configuration: String?
    var source: BuildSource
    var fast: Bool
    var cleanInstall: Bool
    var profileID: String?

    static let initial = RunOptions(scheme: nil, configuration: nil, source: .main, fast: true, cleanInstall: false, profileID: nil)
}

nonisolated enum RunMode: Hashable, Sendable {
    case buildRun
    case runAttach
    case launch

    var title: String {
        switch self {
        case .buildRun: "Build & Run"
        case .runAttach: "Run & Attach"
        case .launch: "Launch"
        }
    }

    var builds: Bool { self != .launch }

    var waitsForDebugger: Bool { self == .runAttach }
}

nonisolated struct InstalledApp: Hashable, Sendable, Identifiable {
    let bundleID: String
    let name: String

    var id: String { bundleID }
}

nonisolated struct SimulatorStatus: Hashable, Sendable {
    let text: String
    let isFailure: Bool
}

nonisolated enum BuildPhase: Hashable, Sendable {
    case idle
    case running(String)
    case succeeded(String)
    case failed(BuildFailure)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}

nonisolated struct BuildFailure: Hashable, Sendable {
    var message: String
    var logPath: String?
}
