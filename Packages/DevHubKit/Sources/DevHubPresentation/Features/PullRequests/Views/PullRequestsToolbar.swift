import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsToolbar: View {
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(GitStore.self) private var git
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    let count: Int

    var body: some View {
        ToolbarBar(controlSize: .regular) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    filters
                    options
                    Spacer()
                    TabSearchField()
                    status
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        filters
                        Spacer()
                        status
                    }
                    HStack(spacing: 8) {
                        options
                        Spacer()
                        TabSearchField()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var filters: some View {
        @Bindable var pullRequests = pullRequests
        Picker("Scope", selection: $pullRequests.scope) {
            ForEach(PullRequestScope.allCases, id: \.self) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .hint("Mine: you opened them. To review: open, not draft, by other people, not approved by you. Assigned: assigned to you. All: every \(words.request) of the project.")
        Picker("State", selection: $pullRequests.stateFilter) {
            ForEach(PullRequestStateFilter.allCases, id: \.self) { state in
                Text(state.title).tag(state)
            }
        }
        .labelsHidden()
        .fixedSize()
        .disabled(pullRequests.scope == .reviewing)
    }

    @ViewBuilder
    private var options: some View {
        @Bindable var pullRequests = pullRequests
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
        .hint("New \(words.request) from the current branch\(git.currentBranch.map { " \($0)" } ?? "")")
    }

    @ViewBuilder
    private var status: some View {
        if pullRequests.isLoading {
            ProgressView()
                .controlSize(.mini)
        }
        Text(CountText.invariant(count, words.requests))
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize()
        IconButton(systemImage: "arrow.clockwise", help: "Read the \(words.requests) again") {
            Task { await pullRequests.refresh() }
        }
    }
}
