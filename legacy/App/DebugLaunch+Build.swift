import AppKit

@MainActor
extension DebugLaunch {
    static func startBuildRun(_ udid: String, in dependencies: AppDependencies) {
        let environment = ProcessInfo.processInfo.environment
        Task {
            try? await Task.sleep(for: .seconds(2))
            await dependencies.simulators.refresh()
            await dependencies.build.loadConfigurations()
            dependencies.simulators.setTarget(udid)
            applyBuildOptions(environment, to: dependencies.build)
            report("BUILD start mode=\(environment["DEVHUB_BUILD_MODE"] ?? "buildrun") target=\(udid)")
            dependencies.build.start(runMode(environment["DEVHUB_BUILD_MODE"]))
            await waitForBuild(dependencies.build)
            if environment["DEVHUB_QUIT_AFTER_BUILD"] == "1" {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private static func runMode(_ name: String?) -> RunMode {
        switch name {
        case "attach": .runAttach
        case "launch": .launch
        default: .buildRun
        }
    }

    private static func applyBuildOptions(_ environment: [String: String], to build: BuildStore) {
        build.setOptions { options in
            if let scheme = environment["DEVHUB_BUILD_SCHEME"] {
                options.scheme = scheme
            }
            if let configuration = environment["DEVHUB_BUILD_CONFIG"] {
                options.configuration = configuration
            }
            if let fast = environment["DEVHUB_BUILD_FAST"] {
                options.fast = fast == "1"
            }
            if let clean = environment["DEVHUB_BUILD_CLEAN_INSTALL"] {
                options.cleanInstall = clean == "1"
            }
            if let profile = environment["DEVHUB_BUILD_PROFILE"] {
                options.profileID = profile
            }
            if let source = environment["DEVHUB_BUILD_SOURCE"] {
                options.source = buildSource(source)
            }
        }
    }

    private static func buildSource(_ text: String) -> BuildSource {
        if text.hasPrefix("branch:") {
            return .branch(String(text.dropFirst("branch:".count)))
        }
        if text.hasPrefix("worktree:") {
            return .worktree(String(text.dropFirst("worktree:".count)))
        }
        return .main
    }

    private static func waitForBuild(_ build: BuildStore) async {
        var ticks = 0
        while build.isRunning {
            try? await Task.sleep(for: .seconds(1))
            ticks += 1
            if ticks % 30 == 0, let text = build.statusText {
                report("BUILD running \(ticks)s: \(text)")
            }
        }
        switch build.phase {
        case let .succeeded(text): report("BUILD succeeded after \(ticks)s: \(text)")
        case let .failed(failure): report("BUILD failed after \(ticks)s: \(failure.message) log=\(failure.logPath ?? "none")")
        case .idle, .running: report("BUILD ended idle after \(ticks)s")
        }
        if let notice = build.attachNotice {
            report("BUILD attach notice: \(notice.message) | \(notice.steps ?? "")")
        }
    }

    private static func report(_ text: String) {
        FileHandle.standardError.write(Data((text + "\n").utf8))
    }
}
