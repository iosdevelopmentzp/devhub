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
                    ForEach(IssueScope.allCases, id: \.self) { scope in
                        Text(TicketsText.title(for: scope)).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint(TicketsText.scopeHint)
                Text(countText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                TicketViewMenu()
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
        tickets.issues.filter { tickets.isShown($0) && session.matchesSearch($0.key, $0.summary, $0.status, $0.assignee ?? "", $0.type) }
    }

    private var content: some View {
        let visible = visible
        return ListState(
            failure: tickets.error.map { ListMessage.failure("Cannot read tickets", description: $0) { Task { await tickets.refresh() } } },
            isLoading: tickets.issues.isEmpty && tickets.isLoading,
            loadingTitle: "Reading tickets…",
            empty: emptyMessage(visible: visible),
            noResultsFor: visible.isEmpty && tickets.issues.isEmpty == false && session.searchText.isEmpty == false ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(TicketSectionMapper.sections(for: visible, grouping: tickets.grouping)) { section in
                        ListSectionHeader(section.title, detail: "\(section.issues.count)") {}
                        ForEach(section.issues) { issue in
                            TicketRow(
                                model: TicketRowMapper.model(
                                    for: issue,
                                    settings: tickets.settings,
                                    isBusy: tickets.busyKeys.contains(issue.key),
                                    isExpanded: tickets.expandedKey == issue.key,
                                    canAssignToMe: tickets.canAssignToMe
                                ),
                                onStart: { tickets.start(issue.key) },
                                onMove: { tickets.move(issue.key, to: $0) },
                                onToggleDetails: { tickets.toggleDetails(issue.key) },
                                onAssignToMe: { tickets.assignToMe(issue.key) }
                            )
                            if tickets.expandedKey == issue.key {
                                details(for: issue)
                            }
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func details(for issue: TrackerIssue) -> some View {
        if let details = tickets.details[issue.key] {
            TicketDetailsView(
                model: TicketDetailsMapper.model(for: details),
                url: issue.url,
                isBusy: tickets.busyKeys.contains(issue.key),
                canAssignToMe: tickets.canAssignToMe,
                onAssignToMe: { tickets.assignToMe(issue.key) },
                onSend: { await tickets.comment(issue.key, text: $0) }
            )
        } else if let message = tickets.detailErrors[issue.key] {
            HStack(spacing: 8) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Button("Try Again") { Task { await tickets.loadDetails(issue.key) } }
                    .buttonStyle(LinkButtonStyle(.accent))
                    .fixedSize()
            }
            .padding(.leading, 56)
            .padding(.trailing, 14)
            .padding(.bottom, 10)
        } else {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Reading \(issue.key)…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 56)
            .padding(.bottom, 10)
        }
    }

    private func emptyMessage(visible: [TrackerIssue]) -> ListMessage? {
        if tickets.issues.isEmpty && tickets.isReady {
            return ListMessage(TicketsText.emptyTitle(includesDone: tickets.includesDone), systemImage: "ticket", description: TicketsText.emptyDescription(for: tickets.scope))
        }
        if visible.isEmpty && tickets.issues.isEmpty == false && session.searchText.isEmpty {
            return ListMessage("Every ticket is hidden by the type filter", systemImage: "line.3.horizontal.decrease.circle", description: "Choose the types to show in the view menu.", actionTitle: "Show All Types") {
                tickets.hiddenTypes = []
            }
        }
        return nil
    }
}

#Preview {
    TicketsView()
        .previewEnvironment()
}
