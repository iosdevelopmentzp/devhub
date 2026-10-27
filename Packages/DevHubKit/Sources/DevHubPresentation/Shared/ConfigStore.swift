import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ConfigStore {
    private(set) var resolved: ResolvedConfig = .empty
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any ConfigRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var watchTask: Task<Void, Never>?
    @ObservationIgnored private var watchedPath: String?
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(repository: any ConfigRepository, session: ProjectSession, events: AppEvents) {
        self.repository = repository
        self.session = session
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                Task { await self.reload() }
            case .refreshRequested(.scripts):
                Task { await self.reload() }
            default:
                break
            }
        }
    }

    var config: ProjectConfig {
        resolved.project
    }

    var issues: [ConfigIssue] {
        resolved.issues
    }

    var tabs: [TabConfig] {
        resolved.tabs
    }

    var globalLayer: ConfigLayerInfo {
        resolved.layers.first { $0.layer == .global }
            ?? ConfigLayerInfo(layer: .global, directory: ProjectPath("~/" + ConfigPaths.folderName).expanded, exists: false)
    }

    var git: GitSettings {
        GitSettingsPolicy.settings(for: resolved.project)
    }

    func effective(detectedSchemes: [String], detectedBaseBranch: String?) -> EffectiveProject {
        EffectiveProjectPolicy.resolve(config: resolved.project, project: session.selectedProject, detectedSchemes: detectedSchemes, detectedBaseBranch: detectedBaseBranch)
    }

    func reload() async {
        guard session.hasProject else {
            stopWatching()
            guard resolved != .empty else { return }
            resolved = .empty
            events.post(.configChanged)
            return
        }
        let path = session.selectedProject.path
        watch(path)
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer { isLoading = false }
            let loaded = await repository.load(projectPath: path)
            try Task.checkCancellation()
            guard session.selectedProject.path == path, loaded != resolved else { return }
            resolved = loaded
            events.post(.configChanged)
        }
    }

    func createExample() async throws -> String {
        let folder = try await repository.createExample(projectPath: session.selectedProject.path)
        await reload()
        return folder
    }

    func createStarter(remote: String, hostKind: CodeHostKind?, baseBranch: String?) async throws -> String {
        let project = session.selectedProject
        let facts = StarterConfigFacts(name: project.name, scheme: project.scheme, bundleID: project.bundleID, remote: remote, hostKind: hostKind, baseBranch: baseBranch)
        let file = try await repository.createStarter(projectPath: project.path, projectJSON: StarterConfigPolicy.projectJSON(facts))
        await reload()
        return file
    }

    func existingFolder() async -> String? {
        await repository.existingFolder(projectPath: session.selectedProject.path)
    }

    private func watch(_ path: String) {
        guard watchedPath != path else { return }
        stopWatching()
        watchedPath = path
        let changes = repository.changes(projectPath: path)
        watchTask = Task { [weak self] in
            for await _ in changes {
                guard let self else { return }
                await reload()
            }
        }
    }

    private func stopWatching() {
        watchTask?.cancel()
        watchTask = nil
        watchedPath = nil
    }
}
