import SwiftUI
import DevHubDomain
import DevHubUI

struct HistorySection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(GitStore.self) private var git
    @Environment(CommitHistoryStore.self) private var history
    @Environment(\.panelOpenCount) private var openCount

    let showsReflog: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let note {
                    Text(note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(14)
                }
                if showsReflog {
                    ForEach(reflogRows) { model in
                        reflogRow(model)
                        Divider().padding(.leading, 14)
                    }
                } else {
                    ForEach(commits) { model in
                        commitRow(model)
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .task(id: "\(taskID)#\(history.scope.rawValue)") {
            guard showsReflog == false, history.scope == .branch else { return }
            await history.refreshBranchCommits()
        }
        .task(id: taskID) {
            guard showsReflog else { return }
            await history.refreshReflog()
        }
    }

    private var taskID: String {
        "\(openCount)#\(showsReflog)#\(git.checkoutPath)#\(git.snapshot?.head ?? "")"
    }

    private var commits: [CommitRowModel] {
        let source = history.scope == .branch ? history.branchCommits : git.state?.history ?? []
        return source
            .filter { session.matchesSearch($0.subject, $0.shortHash, $0.author, $0.refs.map(\.name).joined(separator: " ")) }
            .map { CommitRowMapper.model(for: $0, webBase: git.webURL, expansion: expansion(row: $0.hash, hash: $0.hash)) }
    }

    private var reflogRows: [ReflogRowModel] {
        history.reflog
            .filter { session.matchesSearch($0.message, $0.action, $0.shortHash) }
            .map { ReflogRowMapper.model(for: $0, expansion: expansion(row: $0.selector, hash: $0.hash)) }
    }

    private func expansion(row: String, hash: String) -> CommitRowMapper.Expansion? {
        guard history.expandedRow == row else { return nil }
        return CommitRowMapper.Expansion(files: history.files[hash], error: history.fileErrors[hash], expandedFiles: history.expandedFiles, diffs: history.diffs)
    }

    private var note: String? {
        if showsReflog {
            return history.reflogError.map { "Cannot read the reflog: \($0)" }
        }
        guard history.scope == .branch, history.hasLoadedBranch else { return nil }
        if let error = history.branchError {
            return "Cannot read the commits of this branch: \(error)"
        }
        return history.branchCommits.isEmpty ? "No commits on this branch that are not in \(git.baseName)" : nil
    }

    private func commitRow(_ model: CommitRowModel) -> some View {
        CommitRow(
            model: model,
            onToggle: { history.toggleRow(model.hash, hash: model.hash) },
            onToggleFile: { toggleFile($0, of: model.hash) }
        )
    }

    private func reflogRow(_ model: ReflogRowModel) -> some View {
        ReflogRow(
            model: model,
            onToggle: { history.toggleRow(model.selector, hash: model.hash) },
            onToggleFile: { toggleFile($0, of: model.hash) }
        )
    }

    private func toggleFile(_ path: String, of hash: String) {
        guard let file = history.files[hash]?.first(where: { $0.path == path }) else { return }
        history.toggleFile(file, of: hash)
    }
}

#Preview {
    HistorySection(showsReflog: false)
        .previewEnvironment()
}
