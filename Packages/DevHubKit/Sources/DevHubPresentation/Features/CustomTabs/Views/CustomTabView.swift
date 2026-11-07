import SwiftUI
import DevHubDomain
import DevHubUI

struct CustomTabView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(ConfigActionsStore.self) private var store

    let tab: TabConfig

    var body: some View {
        let sections = CustomTabMapper.sections(for: tab, resolved: config.resolved, placed: store.actions(for: .tab(tab.id)), isVisible: store.isVisible)
        let item = ActionItemContext(tabID: tab.id, inputs: store.tabInputValues(for: tab))
        VStack(spacing: 0) {
            ToolbarBar {
                HStack {
                    Text(CountText.invariant(sections.count, "sections"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TabSearchField()
                }
            }
            Divider()
            if (tab.inputs ?? []).isEmpty == false {
                CustomTabInputsBar(tab: tab)
                Divider()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if sections.isEmpty {
                        Text("This tab has no sections. Add actions or a source script in .devhub/tabs/\(tab.id).json.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(sections) { section in
                        switch section.content {
                        case let .actions(actions, missing):
                            CustomTabActionsSection(title: section.title, actions: actions, missing: missing, slot: "tab.\(tab.id):\(section.id)", item: item)
                        case let .source(action, refresh):
                            CustomTabSourceSection(title: section.title, action: action, refresh: refresh, item: item)
                        case let .missingSource(script):
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(section.title) {}
                                Label("No script \(script) in the .devhub folders", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Tint.red.color)
                            }
                        }
                    }
                    CustomTabHistorySection(tabID: tab.id)
                }
                .padding(14)
            }
        }
        .background(Theme.surface)
    }
}

#Preview {
    CustomTabView(tab: TabConfig(id: "qa", title: "QA", sections: [TabSection(title: "Project", actions: ["builtin.terminal"])]))
        .previewEnvironment()
}
