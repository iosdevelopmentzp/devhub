import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ScriptsStore {
    var scripts: [ScriptAction]
    private(set) var runningIDs: Set<String> = []

    @ObservationIgnored private let activity: ActivityLog

    init(scripts: [ScriptAction], activity: ActivityLog) {
        self.scripts = scripts
        self.activity = activity
    }

    func isRunning(_ id: String) -> Bool {
        runningIDs.contains(id)
    }

    func run(_ script: ScriptAction) {
        simulateRun(id: script.id, title: "Ran \(script.title)", detail: script.fileName) { [weak self] in
            guard let self, let index = scripts.firstIndex(where: { $0.id == script.id }) else { return }
            scripts[index].lastRun = .now
        }
    }

    private func simulateRun(id: String, title: String, detail: String, completion: @escaping () -> Void) {
        guard runningIDs.contains(id) == false else { return }
        runningIDs.insert(id)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1200))
            guard let self else { return }
            runningIDs.remove(id)
            completion()
            activity.log(title, detail: detail, outcome: .success)
        }
    }
}
