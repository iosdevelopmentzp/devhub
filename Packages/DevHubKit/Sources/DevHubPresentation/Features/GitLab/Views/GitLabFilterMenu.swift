import SwiftUI
import DevHubDomain
import DevHubUI

struct GitLabFilterMenu: View {
    @Environment(GitLabStore.self) private var gitLab

    var body: some View {
        @Bindable var gitLab = gitLab
        let options = gitLab.filterOptions
        Menu {
            Picker("Target branch", selection: $gitLab.filter.targetBranch) {
                Text("Any target branch").tag(String?.none)
                ForEach(options.targetBranches, id: \.self) { branch in
                    Text(branch).tag(String?.some(branch))
                }
            }
            Picker("Label", selection: $gitLab.filter.label) {
                Text("Any label").tag(String?.none)
                ForEach(options.labels, id: \.self) { label in
                    Text(label).tag(String?.some(label))
                }
            }
            Divider()
            Toggle("Only with conflicts", isOn: $gitLab.filter.onlyConflicts)
            Toggle("Only ready to merge", isOn: $gitLab.filter.onlyReady)
            Divider()
            Button("Clear Filters") { gitLab.clearFilter() }
                .disabled(gitLab.filter.isActive == false)
        } label: {
            Image(systemName: gitLab.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(gitLab.filter.isActive ? Color.accentColor : .secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint("Filter by target branch, label, conflicts, ready to merge")
    }
}

#Preview {
    GitLabFilterMenu()
        .previewEnvironment()
        .padding()
}
