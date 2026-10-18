import SwiftUI
import DevHubDomain
import DevHubUI

struct MockRulesView: View {
    @Environment(NetworkStore.self) private var network
    @Environment(MockServerStore.self) private var mockServer
    @Environment(MockSetsStore.self) private var mockSets

    var body: some View {
        let current = currentSet
        return VStack(spacing: 0) {
            MockSetBar(
                sets: MockServerBarMapper.model(settings: .off, state: nil, sets: mockSets.sets, hasSimulator: false, isApplying: false, needsApply: false, error: nil, app: nil, report: nil, lastLaunch: nil, profiles: []).sets,
                selectedSetID: current?.id,
                selectedName: current?.name,
                onSelect: select,
                onCreate: { select(mockSets.createSet(name: "New set")) },
                onRename: { name in
                    guard let id = current?.id else { return }
                    mockSets.renameSet(id: id, to: name)
                },
                onDuplicate: {
                    guard let id = current?.id else { return }
                    select(mockSets.duplicateSet(id: id))
                },
                onDelete: {
                    guard let id = current?.id else { return }
                    mockSets.deleteSet(id: id)
                    select(mockSets.sets.first?.id)
                },
                onAddRule: {
                    guard let id = current?.id else { return }
                    mockSets.addRule(to: id)
                }
            )
            Divider()
            ListState(
                failure: mockSets.error.map { ListMessage.failure("Mock sets", description: $0) { Task { await mockSets.load() } } },
                isLoading: mockSets.isLoading && mockSets.sets.isEmpty,
                loadingTitle: "Loading mock sets…",
                empty: emptyMessage(current),
                noResultsFor: nil
            ) {
                if let current {
                    list(current)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func list(_ set: MockSet) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(set.rules) { rule in
                    let isEditing = mockSets.editingRuleID == rule.id
                    MockRuleRow(
                        model: MockRuleRowMapper.model(for: rule, isEditing: isEditing),
                        onToggleEnabled: { mockSets.toggleRule(id: rule.id, in: set.id) },
                        onEdit: { mockSets.toggleEditing(rule.id) },
                        onDelete: { mockSets.deleteRule(id: rule.id, in: set.id) }
                    )
                    if isEditing {
                        MockRuleEditor(
                            rule: rule,
                            onSave: { mockSets.saveRule($0, in: set.id) },
                            onCancel: { mockSets.editingRuleID = nil }
                        )
                        .id(rule.id)
                    }
                    if rule.id != set.rules.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var currentSet: MockSet? {
        let chosen = network.selectedUDID.flatMap { mockServer.settings(for: $0).setID }.flatMap(mockSets.set(id:))
        return chosen ?? mockSets.sets.first
    }

    private func select(_ id: MockSet.ID?) {
        guard let udid = network.selectedUDID else { return }
        mockServer.selectSet(id, for: udid)
    }

    private func emptyMessage(_ current: MockSet?) -> ListMessage? {
        guard let current else {
            return ListMessage(
                "No mock sets",
                systemImage: "theatermasks",
                description: "A mock set is a list of rules that answer or change responses. Create one here, or press Mock This on a request.",
                actionTitle: "New Set"
            ) {
                select(mockSets.createSet(name: "New set"))
            }
        }
        guard current.rules.isEmpty else { return nil }
        return ListMessage(
            "No rules in \(current.name)",
            systemImage: "list.bullet.rectangle",
            description: "Add a rule, or open a request in the list and press Mock This.",
            actionTitle: "Add Rule"
        ) {
            mockSets.addRule(to: current.id)
        }
    }
}

#Preview {
    MockRulesView()
        .previewEnvironment()
}
