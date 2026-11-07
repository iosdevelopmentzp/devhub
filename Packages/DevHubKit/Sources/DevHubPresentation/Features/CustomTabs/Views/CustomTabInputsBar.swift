import SwiftUI
import DevHubDomain
import DevHubUI

struct CustomTabInputsBar: View {
    @Environment(ConfigActionsStore.self) private var store

    let tab: TabConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(tab.inputs ?? []) { input in
                ConfigActionInputField(input: input, value: binding(for: input), recent: recent(for: input))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.base)
    }

    private func binding(for input: ActionInput) -> Binding<String> {
        Binding(
            get: { store.tabInputValues(for: tab)[input.key] ?? "" },
            set: { store.setTabInput($0, for: input.key, tab: tab) }
        )
    }

    private func recent(for input: ActionInput) -> RecentInputValues? {
        guard input.recent == true else { return nil }
        let scope = store.tabScope(tab.id)
        return RecentInputValues(
            values: store.recentValues(for: input.key, scope: scope),
            forget: { store.forgetRecent($0, for: input.key, scope: scope) }
        )
    }
}

#Preview {
    CustomTabInputsBar(tab: TabConfig(id: "chat", title: "Chat", inputs: [
        ActionInput(key: "env", title: "Environment", type: .choice, options: [InputOption(value: "/qabot", title: "QA"), InputOption(value: "/prodbot", title: "PROD", confirm: "Send to PROD?")], defaultValue: "/qabot"),
        ActionInput(key: "user", title: "User ID", type: .text, recent: true),
    ]))
    .previewEnvironment()
}
