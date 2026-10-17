import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsFilterMenu: View {
    @Environment(PullRequestsStore.self) private var pullRequests

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
            Picker("Label", selection: $pullRequests.filter.label) {
                Text("Any label").tag(String?.none)
                ForEach(options.labels, id: \.self) { label in
                    Text(label).tag(String?.some(label))
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
        .hint("Filter by target branch, label, conflicts, ready to merge")
    }
}

#Preview {
    PullRequestsFilterMenu()
        .previewEnvironment()
        .padding()
}
