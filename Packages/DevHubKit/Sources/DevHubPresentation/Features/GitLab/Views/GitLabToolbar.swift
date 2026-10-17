import SwiftUI
import DevHubDomain
import DevHubUI

struct GitLabToolbar: View {
    @Environment(GitLabStore.self) private var gitLab
    @Environment(GitStore.self) private var git
    @Environment(AppActions.self) private var appActions

    let count: Int

    var body: some View {
        @Bindable var gitLab = gitLab
        ToolbarBar(controlSize: .regular) {
            HStack(spacing: 8) {
                Picker("Scope", selection: $gitLab.scope) {
                    ForEach(MergeRequestScope.allCases, id: \.self) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("Mine: you opened them. To review: open, not draft, by other people, not approved by you. Assigned: assigned to you. All: every merge request of the project.")
                Picker("State", selection: $gitLab.stateFilter) {
                    ForEach(MergeRequestStateFilter.allCases, id: \.self) { state in
                        Text(state.title).tag(state)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .disabled(gitLab.scope == .reviewing)
                GitLabFilterMenu()
                Menu {
                    Picker("View", selection: $gitLab.listStyle) {
                        ForEach(MergeRequestListStyle.allCases, id: \.self) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label(gitLab.listStyle.title, systemImage: "list.bullet.rectangle")
                }
                .fixedSize()
                .hint("How the list looks. \(MergeRequestListStyle.allCases.map { "\($0.title): \($0.hint)." }.joined(separator: " "))")
                Button("New…", systemImage: "plus") {
                    guard let branch = git.currentBranch else { return }
                    appActions.startMergeRequest(branch: branch, origin: .gitLab)
                }
                .fixedSize()
                .disabled(git.currentBranch == nil)
                .hint("New merge request from the current branch\(git.currentBranch.map { " \($0)" } ?? "")")
                Spacer()
                if gitLab.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(CountText.invariant(count, "merge requests"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                IconButton(systemImage: "arrow.clockwise", help: "Read the merge requests again") {
                    Task { await gitLab.refresh() }
                }
            }
        }
    }
}
