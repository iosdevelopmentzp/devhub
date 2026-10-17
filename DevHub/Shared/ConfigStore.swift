import Foundation
import Observation

@MainActor
@Observable
final class ConfigStore {
    private(set) var resolved: ResolvedConfig = .empty
    private(set) var isLoading = false

    @ObservationIgnored private let provider: ConfigProviding
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private var watcher: ConfigWatching?
    @ObservationIgnored private var watchedPath: String?

    init(provider: ConfigProviding, session: ProjectSession, events: AppEvents) {
        self.provider = provider
        self.session = session
        self.events = events
        events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            Task { await self.reload() }
        }
    }

    var config: ProjectConfig { resolved.project }

    var issues: [ConfigIssue] { resolved.issues }

    var effective: EffectiveProject? {
        guard let project = session.project else { return nil }
        return EffectiveProject(config: resolved.project, detection: session.detection, folderName: project.name)
    }

    func effective(for project: Project, isCurrent: Bool) -> EffectiveProject {
        let config = isCurrent ? resolved.project : .empty
        return EffectiveProject(config: config, detection: session.detections[project.path], folderName: project.name)
    }

    func reload() async {
        guard let current = session.project else {
            watcher?.stop()
            watcher = nil
            watchedPath = nil
            resolved = .empty
            return
        }
        isLoading = true
        defer { isLoading = false }
        arm(for: current)
        let loaded = await provider.load(projectPath: current.path)
        guard session.project == current else { return }
        resolved = loaded
        events.post(.configChanged)
    }

    func createExample(for project: Project) throws -> String {
        let folder = try provider.createExample(projectPath: project.path)
        if session.project == project {
            Task { await reload() }
        }
        return folder
    }

    func folderToReveal(for project: Project) -> String? {
        provider.folderToReveal(projectPath: project.path)
    }

    func scriptsFolder() -> String? {
        for layer in [ConfigLayer.user, .project, .global] {
            guard let info = resolved.layers.first(where: { $0.layer == layer }) else { continue }
            let folder = info.directory + "/scripts"
            if FileManager.default.fileExists(atPath: folder) {
                return folder
            }
        }
        return nil
    }

    private func arm(for project: Project) {
        guard watchedPath != project.path else { return }
        watcher?.stop()
        watchedPath = project.path
        watcher = provider.makeWatcher(projectPath: project.path) { [weak self] in
            guard let self else { return }
            Task { await self.reload() }
        }
    }
}
