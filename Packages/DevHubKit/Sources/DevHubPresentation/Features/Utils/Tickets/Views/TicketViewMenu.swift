import SwiftUI
import DevHubDomain
import DevHubUI

struct TicketViewMenu: View {
    @Environment(TicketsStore.self) private var tickets

    var body: some View {
        @Bindable var tickets = tickets
        Menu {
            Picker("Group by", selection: $tickets.grouping) {
                ForEach(TicketGrouping.allCases, id: \.self) { grouping in
                    Text(grouping.title).tag(grouping)
                }
            }
            Picker("Sort by", selection: $tickets.order) {
                ForEach(IssueOrder.allCases, id: \.self) { order in
                    Text(TicketsText.title(for: order)).tag(order)
                }
            }
            Divider()
            Toggle(TicketsText.doneToggleTitle, isOn: $tickets.includesDone)
            Menu(TicketsText.typesTitle(hidden: tickets.hiddenTypes.count)) {
                if tickets.types.isEmpty {
                    Text("No types in the loaded tickets")
                }
                ForEach(tickets.types, id: \.self) { type in
                    Toggle(type, isOn: typeBinding(type))
                }
                if tickets.hiddenTypes.isEmpty == false {
                    Divider()
                    Button("Show All Types") { tickets.hiddenTypes = [] }
                }
            }
            Divider()
            Button("Reset View") { tickets.resetView() }
                .disabled(tickets.isDefaultView)
        } label: {
            Image(systemName: tickets.isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(tickets.isFiltered ? Color.accentColor : .secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint(TicketsText.viewHint)
    }

    private func typeBinding(_ type: String) -> Binding<Bool> {
        Binding(
            get: { tickets.hiddenTypes.contains(type) == false },
            set: { _ in tickets.toggleType(type) }
        )
    }
}

#Preview {
    TicketViewMenu()
        .previewEnvironment()
}
