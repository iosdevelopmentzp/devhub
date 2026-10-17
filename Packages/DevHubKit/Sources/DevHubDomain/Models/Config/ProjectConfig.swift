import Foundation

package struct ProjectConfig: Codable, Hashable, Sendable {
    package var name: String? = nil
    package var kind: ProjectKind? = nil
    package var xcode: XcodeConfig? = nil
    package var build: CommandConfig? = nil
    package var run: CommandConfig? = nil
    package var git: GitConfig? = nil
    package var launch: LaunchConfig? = nil
    package var logs: LogsConfig? = nil
    package var simulators: SimulatorsConfig? = nil
    package var home: HomeConfig? = nil
    package var ai: AIConfig? = nil

    package static let empty = ProjectConfig()

    package init(
        name: String? = nil,
        kind: ProjectKind? = nil,
        xcode: XcodeConfig? = nil,
        build: CommandConfig? = nil,
        run: CommandConfig? = nil,
        git: GitConfig? = nil,
        launch: LaunchConfig? = nil,
        logs: LogsConfig? = nil,
        simulators: SimulatorsConfig? = nil,
        home: HomeConfig? = nil,
        ai: AIConfig? = nil
    ) {
        self.name = name
        self.kind = kind
        self.xcode = xcode
        self.build = build
        self.run = run
        self.git = git
        self.launch = launch
        self.logs = logs
        self.simulators = simulators
        self.home = home
        self.ai = ai
    }
}
