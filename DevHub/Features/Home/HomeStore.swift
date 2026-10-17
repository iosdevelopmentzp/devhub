import Foundation
import Observation

@MainActor
@Observable
final class HomeStore {
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let projectActions: ProjectActions

    init(session: ProjectSession, config: ConfigStore, projectActions: ProjectActions) {
        self.session = session
        self.config = config
        self.projectActions = projectActions
    }

    func refresh() async {
        await session.refresh()
    }

    func reloadConfig() {
        Task { await config.reload() }
    }

    func revealInFinder() {
        projectActions.revealInFinder()
    }

    func openInEditor() {
        projectActions.openInEditor()
    }

    func openTerminal() {
        projectActions.openTerminal()
    }

    func openRepository() {
        projectActions.openRepository()
    }

    func revealScriptsFolder() {
        guard let folder = config.scriptsFolder() else {
            projectActions.fail("Open scripts folder", "There is no scripts folder yet. Create the .devhub example in Settings.")
            return
        }
        projectActions.reveal(folder, title: "Open scripts folder")
    }
}
