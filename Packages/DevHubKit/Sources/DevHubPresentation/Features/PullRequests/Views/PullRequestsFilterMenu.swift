import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsFilterMenu: View {
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(\.codeHostWords) private var words

    var body: some View {
        @Bindable var pullRequests = pullRequests
        let options = pullRequests.filterOptions
        Menu {
            Picker("Target branch", selection: $pullRequests.filter.targetBranch) {
                Text("Any target branch").tag(String?.none)
                ForEach(options.targetBranches, id: \.self) { branch in
                    Text(branch).tag(String?.some(branch))
                }
            }
            Menu(labelsTitle(pullRequests.filter)) {
                if options.labels.isEmpty {
                    Text("No labels in the loaded \(words.requests)")
                }
                ForEach(options.labels, id: \.self) { label in
                    Toggle(label, isOn: labelBinding(label))
                }
                if pullRequests.filter.labels.isEmpty == false {
                    Divider()
                    Button("Any label") { pullRequests.filter.labels = [] }
                }
            }
            Picker("Author", selection: $pullRequests.filter.author) {
                Text("Any author").tag(String?.none)
                ForEach(options.authors, id: \.self) { author in
                    Text(author).tag(String?.some(author))
                }
            }
            Picker("Assignee", selection: $pullRequests.filter.assignee) {
                Text("Any assignee").tag(String?.none)
                ForEach(options.assignees, id: \.self) { assignee in
                    Text(assignee).tag(String?.some(assignee))
                }
            }
            Picker("Reviewer", selection: $pullRequests.filter.reviewer) {
                Text("Any reviewer").tag(String?.none)
                ForEach(options.reviewers, id: \.self) { reviewer in
                    Text(reviewer).tag(String?.some(reviewer))
                }
            }
            Divider()
            Toggle("Only with conflicts", isOn: $pullRequests.filter.onlyConflicts)
            Toggle("Only ready to merge", isOn: $pullRequests.filter.onlyReady)
            Divider()
            Button("Clear Filters") { pullRequests.clearFilter() }
                .disabled(pullRequests.filter.isActive == false)
        } label: {
            Image(systemName: pullRequests.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(pullRequests.filter.isActive ? Color.accentColor : .secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint("Filter by target branch, labels, author, assignee, reviewer, conflicts, ready to merge. A click on a label in a row filters by it too.")
    }

    private func labelsTitle(_ filter: PullRequestFilter) -> String {
        filter.labels.isEmpty ? "Labels" : "Labels (\(filter.labels.count))"
    }

    private func labelBinding(_ label: String) -> Binding<Bool> {
        Binding(
            get: { pullRequests.filter.labels.contains(label) },
            set: { _ in pullRequests.toggleLabel(label) }
        )
    }
}

#Preview {
    PullRequestsFilterMenu()
        .previewEnvironment()
        .padding()
}
