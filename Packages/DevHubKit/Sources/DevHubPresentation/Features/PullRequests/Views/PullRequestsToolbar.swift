import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsToolbar: View {
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(GitStore.self) private var git
    @Environment(AppActions.self) private var appActions

    let count: Int

    var body: some View {
        @Bindable var pullRequests = pullRequests
        ToolbarBar(controlSize: .regular) {
            HStack(spacing: 8) {
                Picker("Scope", selection: $pullRequests.scope) {
                    ForEach(PullRequestScope.allCases, id: \.self) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("Mine: you opened them. To review: open, not draft, by other people, not approved by you. Assigned: assigned to you. All: every merge request of the project.")
                Picker("State", selection: $pullRequests.stateFilter) {
                    ForEach(PullRequestStateFilter.allCases, id: \.self) { state in
                        Text(state.title).tag(state)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .disabled(pullRequests.scope == .reviewing)
                PullRequestsFilterMenu()
                Menu {
                    Picker("View", selection: $pullRequests.listStyle) {
                        ForEach(PullRequestListStyle.allCases, id: \.self) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label(pullRequests.listStyle.title, systemImage: "list.bullet.rectangle")
                }
                .fixedSize()
                .hint("How the list looks. \(PullRequestListStyle.allCases.map { "\($0.title): \($0.hint)." }.joined(separator: " "))")
                Button("New…", systemImage: "plus") {
                    guard let branch = git.currentBranch else { return }
                    appActions.startPullRequest(branch: branch, origin: .pullRequests)
                }
                .fixedSize()
                .disabled(git.currentBranch == nil)
                .hint("New merge request from the current branch\(git.currentBranch.map { " \($0)" } ?? "")")
                Spacer()
                if pullRequests.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(CountText.invariant(count, "merge requests"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                IconButton(systemImage: "arrow.clockwise", help: "Read the merge requests again") {
                    Task { await pullRequests.refresh() }
                }
            }
        }
    }
}
