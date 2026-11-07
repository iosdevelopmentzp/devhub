import SwiftUI
import DevHubDomain
import DevHubUI

struct TicketsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(TicketsStore.self) private var tickets
    @Environment(\.panelOpenCount) private var openCount

    var body: some View {
        VStack(spacing: 0) {
            if tickets.isEnabled {
                toolbar
                Divider()
                TrackerToolCard(
                    model: TrackerToolMapper.model(for: tickets.toolState, isChecking: tickets.isLoading),
                    onCheckAgain: { Task { await tickets.refresh() } }
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ListState(failure: nil, isLoading: false, loadingTitle: "", empty: ListMessage(TrackerText.noTrackerTitle, systemImage: "ticket", description: TrackerText.noTrackerDescription), noResultsFor: nil) {
                    EmptyView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.surface)
        .task(id: openCount) {
            await tickets.refresh()
        }
    }

    private var toolbar: some View {
        @Bindable var tickets = tickets
        return ToolbarBar {
            HStack(spacing: 10) {
                Picker("Scope", selection: $tickets.scope) {
                    Text("Mine").tag(IssueScope.mine)
                    Text("Project").tag(IssueScope.project)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("Mine: open tickets assigned to you. Project: every open ticket of the project.")
                Text(countText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                IconButton(systemImage: "arrow.clockwise", help: "Read the tickets again") {
                    Task { await tickets.refresh() }
                }
                .disabled(tickets.isLoading)
            }
        }
    }

    private var countText: String {
        let total = tickets.issues.count
        let shown = visible.count
        guard shown != total else { return CountText.invariant(total, "tickets") }
        return "\(shown) of \(CountText.invariant(total, "tickets"))"
    }

    private var visible: [TrackerIssue] {
        tickets.issues.filter { session.matchesSearch($0.key, $0.summary, $0.status, $0.assignee ?? "") }
    }

    private var content: some View {
        ListState(
            failure: tickets.error.map { ListMessage.failure("Cannot read tickets", description: $0) { Task { await tickets.refresh() } } },
            isLoading: tickets.issues.isEmpty && tickets.isLoading,
            loadingTitle: "Reading tickets…",
            empty: tickets.issues.isEmpty && tickets.isReady ? ListMessage("No open tickets", systemImage: "ticket", description: emptyDescription) : nil,
            noResultsFor: visible.isEmpty && tickets.issues.isEmpty == false ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(TicketSectionMapper.sections(for: visible)) { section in
                        ListSectionHeader(section.title, detail: "\(section.issues.count)") {}
                        ForEach(section.issues) { issue in
                            TicketRow(
                                model: TicketRowMapper.model(for: issue, settings: tickets.settings, isBusy: tickets.busyKeys.contains(issue.key)),
                                onStart: { tickets.start(issue.key) },
                                onMove: { tickets.move(issue.key, to: $0) }
                            )
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var emptyDescription: String {
        switch tickets.scope {
        case .mine: "Nothing open is assigned to you in this project."
        case .project: "The project has no open tickets."
        }
    }
}

#Preview {
    TicketsView()
        .previewEnvironment()
}
