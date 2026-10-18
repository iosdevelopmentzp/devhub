import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class AISessionsStore {
    enum Scope: String, CaseIterable, Identifiable {
        case project = "This project"
        case all = "All"

        var id: String { rawValue }
    }

    private(set) var sessions: [AISession] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    var scope: Scope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Self.scopeKey)
        }
    }

    @ObservationIgnored private let repository: AISessionRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let refreshTask = RefreshTask()

    private static let scopeKey = "claude.scope"

    init(repository: AISessionRepository, session: ProjectSession, store: any KeyValueStore) {
        self.repository = repository
        self.session = session
        self.store = store
        let stored = store.string(forKey: Self.scopeKey)
        scope = stored.flatMap(Scope.init(rawValue:)) ?? .project
    }

    var scoped: [AISession] {
        guard scope == .project else { return sessions }
        let root = ProjectPath(session.selectedProject.path).expanded
        return sessions.filter { $0.cwd == root || $0.cwd.hasPrefix(root + "/") }
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            let loaded = await repository.sessions()
            try Task.checkCancellation()
            sessions = loaded
            isLoading = false
            hasLoaded = true
        }
    }
}
