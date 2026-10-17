import Foundation
import Observation

@MainActor
@Observable
final class SettingsTabStore {
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let projectActions: ProjectActions
    @ObservationIgnored private let settings: SettingsStore

    init(session: ProjectSession, config: ConfigStore, projectActions: ProjectActions, settings: SettingsStore) {
        self.session = session
        self.config = config
        self.projectActions = projectActions
        self.settings = settings
    }

    var globalConfigPath: String {
        NSHomeDirectory() + "/.devhub"
    }

    func revealGlobalConfig() {
        projectActions.reveal(globalConfigPath, title: "Reveal config folder")
    }

    func revealConfigFolder(of project: Project) {
        guard let folder = config.folderToReveal(for: project) else {
            projectActions.fail("Open .devhub folder", "\(project.name) has no .devhub folder yet. Use Create .devhub example.")
            return
        }
        projectActions.reveal(folder, title: "Open .devhub folder")
    }

    func createExample(for project: Project) {
        do {
            let folder = try config.createExample(for: project)
            projectActions.record("Create .devhub example", detail: folder)
        } catch {
            projectActions.fail("Create .devhub example", error.localizedDescription)
        }
    }

    func redetect(_ project: Project) {
        Task { await session.redetect(project) }
    }
}
