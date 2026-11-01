import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class XcodeSelectionStore {
    private(set) var installations: [XcodeInstallation] = []
    private(set) var systemDeveloperDir: String?
    private(set) var appliedDeveloperDir: String?

    @ObservationIgnored private let repository: any XcodeInstallationRepository
    @ObservationIgnored private let environment: any ToolEnvironmentRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        repository: any XcodeInstallationRepository,
        environment: any ToolEnvironmentRepository,
        session: ProjectSession,
        config: ConfigStore,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.repository = repository
        self.environment = environment
        self.session = session
        self.config = config
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged, .configChanged:
                Task { await self.apply() }
            default:
                break
            }
        }
        Task { [weak self] in
            await self?.apply()
        }
    }

    var configDeveloperDir: String? {
        config.config.xcode?.developerDir
    }

    var effectiveDeveloperDir: String? {
        DeveloperDirPolicy.effective(choice: session.selectedProject.developerDir, config: configDeveloperDir)
    }

    func refresh() async {
        do {
            installations = try await repository.installations()
            systemDeveloperDir = try await repository.selectedDeveloperDir()
        } catch {
            activity.log("Cannot list the installed Xcode apps", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func apply() async {
        let developerDir = effectiveDeveloperDir
        guard developerDir != appliedDeveloperDir else { return }
        appliedDeveloperDir = developerDir
        await environment.setDeveloperDir(developerDir)
    }

    func choose(_ developerDir: String?, for project: Project) {
        var updated = project
        updated.developerDir = developerDir.flatMap { $0.isEmpty ? nil : $0 }
        session.update(updated)
        Task { await apply() }
    }
}
