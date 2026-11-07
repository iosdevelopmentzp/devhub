#if DEBUG
import Foundation
import DevHubDomain

package extension PresentationAssembly {
    func debugAddProject(path: String) {
        session.addProject(at: ProjectPath(path).url)
    }

    func debugSetWindowMode(_ rawValue: String) {
        guard let mode = WindowMode(rawValue: rawValue) else { return }
        settings.values.windowMode = mode
    }

    func debugShowPullRequest(_ value: String) {
        guard let iid = Int(value) else { return }
        appActions.showPullRequest(iid: iid)
    }

    func debugPullRequest(_ value: String) async -> PullRequestSummary? {
        guard let iid = Int(value) else { return nil }
        await pullRequests.reveal(iid)
        return pullRequests.requests.first { $0.id == iid }
    }

    func debugRevealFile(_ path: String, in value: String) async {
        guard let iid = Int(value) else { return }
        for _ in 0..<50 where pullRequestDetails.isLoaded(iid) == false {
            try? await Task.sleep(for: .milliseconds(100))
        }
        try? await Task.sleep(for: .milliseconds(500))
        pullRequestDetails.revealFile(path, of: iid)
    }

    func debugSetDiffLayout(_ rawValue: String) {
        guard let layout = DiffLayout(rawValue: rawValue) else { return }
        pullRequests.diffLayout = layout
    }

    func debugExpandGitRow(_ value: String) async {
        for _ in 0..<50 where git.state == nil {
            try? await Task.sleep(for: .milliseconds(100))
        }
        if value.hasPrefix("stash:"), let index = Int(value.dropFirst(6)), let stash = git.stashes.first(where: { $0.index == index }) {
            history.toggleStash(stash)
            await debugExpandFirstFile(of: stash.hash)
        } else if value.hasPrefix("commit:") {
            let hash = String(value.dropFirst(7))
            history.toggleRow(hash, hash: hash)
            await debugExpandFirstFile(of: hash)
        }
    }

    private func debugExpandFirstFile(of hash: String) async {
        for _ in 0..<50 where history.files[hash] == nil {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard let file = history.files[hash]?.first else { return }
        history.toggleFile(file, of: hash)
    }

    func debugShowGitSection(_ rawValue: String) {
        guard let section = GitStore.Section(rawValue: rawValue) else { return }
        git.section = section
    }

    func debugShowTab(_ rawValue: String) {
        guard let tab = TabID(rawValue: rawValue) else { return }
        navigator.show(tab)
    }

    func debugOpenPalette(query: String) {
        navigator.paletteQuery = query
        navigator.isPaletteOpen = true
    }

    func debugShowOutput() {
        output.isVisible = true
    }

    func debugStreamLogs(_ targets: [String]) async {
        await simulators.refresh()
        await config.reload()
        for target in targets {
            guard let simulator = simulators.all.first(where: { $0.id == target || $0.name == target }) else {
                activity.log("Debug logs", detail: "No simulator \(target).", outcome: .failure)
                continue
            }
            logs.stream(on: simulator.id)
        }
    }

    func debugRunAction(_ id: String, prompt: Bool) async {
        await worktrees.refresh()
        await simulators.refresh()
        await config.reload()
        guard let action = config.resolved.action(id: id) else {
            activity.log("Debug run", detail: "No action with id \(id).", outcome: .failure)
            return
        }
        if prompt {
            configActions.request(action, item: .none, slot: "home.scripts:\(action.id)")
        } else {
            configActions.runWithDefaults(action, item: .none)
        }
    }
}
#endif
