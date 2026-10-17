import AppKit

@MainActor
enum DebugLaunch {
    static func apply(to dependencies: AppDependencies) {
        let environment = ProcessInfo.processInfo.environment
        if let path = environment["DEVHUB_PROJECT"] {
            dependencies.session.add(path: path)
        }
        for id in (environment["DEVHUB_RUN_ACTION"] ?? "").split(separator: ",") {
            runAction(String(id), in: dependencies, prompt: false)
        }
        if let id = environment["DEVHUB_REQUEST_ACTION"] {
            runAction(id, in: dependencies, prompt: true)
        }
        if environment["DEVHUB_LOG_REDACT_CHECK"] == "1" {
            checkRedaction()
        }
        if let streams = environment["DEVHUB_LOG_STREAM"] {
            startLogStreams(streams, in: dependencies)
        }
        if let udid = environment["DEVHUB_BUILD_RUN"] {
            startBuildRun(udid, in: dependencies)
        }
        if let script = environment["DEVHUB_GIT_OPS"] {
            DebugGitOps.run(script, in: dependencies)
        }
        guard environment["DEVHUB_OPEN_PANEL"] == "1" else { return }
        if let tab = environment["DEVHUB_TAB"] {
            dependencies.navigator.show(tab)
        }
        if environment["DEVHUB_CREATE_EXAMPLE"] == "1" {
            createExample(in: dependencies)
        }
        if let segment = environment["DEVHUB_GIT_SEGMENT"].flatMap(GitSegment.init(rawValue:)) {
            dependencies.git.selectSegment(segment)
        }
        if let query = environment["DEVHUB_SEARCH"] {
            dependencies.session.searchText = query
        }
        if let scope = environment["DEVHUB_AI_SCOPE"].flatMap(AIScope.init(rawValue:)) {
            dependencies.ai.scope = scope
        }
        if let filter = environment["DEVHUB_AI_PROVIDER"].flatMap(AIProviderFilter.init(rawValue:)) {
            dependencies.ai.providerFilter = filter
        }
        if environment["DEVHUB_USAGE_EXPAND"] == "1" {
            dependencies.usage.isExpanded = true
        }
        if environment["DEVHUB_SHOW_OUTPUT"] == "1" {
            dependencies.outputPanel.isVisible = true
        }
        let delay = Double(environment["DEVHUB_SNAPSHOT_DELAY"] ?? "") ?? 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dependencies.windows?.showPanel()
            guard let path = environment["DEVHUB_SNAPSHOT"] else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                writeSnapshot(of: dependencies.windows?.panel?.contentView, to: path)
            }
        }
    }

    private static func createExample(in dependencies: AppDependencies) {
        Task {
            try? await Task.sleep(for: .seconds(2))
            guard let project = dependencies.session.project else { return }
            dependencies.settingsTab.createExample(for: project)
        }
    }

    private static func runAction(_ id: String, in dependencies: AppDependencies, prompt: Bool) {
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard let action = dependencies.catalog.action(id: id) else {
                dependencies.activity.log("Debug run", detail: "No action with id \(id).", outcome: .failure)
                return
            }
            if prompt {
                dependencies.runner.request(action, item: .none, slot: "home.scripts:\(action.id)")
            } else {
                dependencies.runner.runWithDefaults(action, item: .none)
            }
        }
    }

    private static func writeSnapshot(of view: NSView?, to path: String) {
        guard let view, let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: representation)
        try? representation.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}
