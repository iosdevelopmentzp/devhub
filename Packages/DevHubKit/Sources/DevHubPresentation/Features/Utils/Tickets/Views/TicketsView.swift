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
                    onCheckAgain: { Task { await tickets.reload() } }
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if let error = tickets.error, tickets.issues.isEmpty == false {
                    NoticeBar(TicketsText.staleNotice(error), actionTitle: "Retry") {
                        Task { await tickets.reload() }
                    }
                }
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
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        count
                        if let read = TicketsText.readText(tickets.readAt) {
                            Text(read)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .fixedSize()
                                .hint("When the list was last read from Jira. The list is kept between launches and read again on every open.")
                        }
                    }
                    count
                }
                Spacer(minLength: 4)
                TicketViewMenu()
                if tickets.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: IconButton.side, height: IconButton.side)
                } else {
                    IconButton(systemImage: "arrow.clockwise", help: "Read the tickets again and check jira") {
                        Task { await tickets.reload() }
                    }
                }
            }
        }
    }

    private var count: some View {
        Text(countText)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var countText: String {
        let total = tickets.issues.count
        let shown = visible.count
        guard shown != total else { return CountText.invariant(total, "tickets") }
        return "\(shown) of \(CountText.invariant(total, "tickets"))"
    }

    private var visible: [TrackerIssue] {
        tickets.issues.filter { tickets.isShown($0) && session.matchesSearch($0.key, $0.summary, $0.status, $0.assignee ?? "", $0.type, $0.labels.joined(separator: " ")) }
    }

    private var content: some View {
        let visible = visible
        let now = Date.now
        return ListState(
            failure: tickets.issues.isEmpty ? tickets.error.map { ListMessage.failure(TicketsText.readFailureTitle, description: $0) { Task { await tickets.reload() } } } : nil,
            isLoading: tickets.issues.isEmpty && tickets.isLoading,
            loadingTitle: "Reading tickets…",
            empty: emptyMessage(visible: visible),
            noResultsFor: visible.isEmpty && tickets.issues.isEmpty == false && session.searchText.isEmpty == false ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(TicketSectionMapper.sections(for: visible, grouping: tickets.grouping, starred: tickets.pinnedKeys)) { section in
                        ListSectionHeader(section.title, detail: "\(section.issues.count)") {}
                        ForEach(section.issues) { issue in
                            row(for: issue, now: now)
                            if tickets.expandedKey == issue.key {
                                details(for: issue, now: now)
                            }
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                    if tickets.canLoadMore {
                        Button(TicketsText.loadMoreTitle) { tickets.loadMore() }
                            .buttonStyle(LinkButtonStyle(.accent))
                            .fixedSize()
                            .hint(TicketsText.loadMoreHint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func row(for issue: TrackerIssue, now: Date) -> some View {
        TicketRow(
            model: TicketRowMapper.model(
                for: issue,
                settings: tickets.settings,
                isBusy: tickets.busyKeys.contains(issue.key),
                isExpanded: tickets.expandedKey == issue.key,
                isStarred: tickets.isStarred(issue.key),
                canAssignToMe: tickets.canAssignToMe,
                canWatch: tickets.canWatch,
                now: now
            ),
            onStart: { tickets.start(issue.key) },
            onMove: { tickets.move(issue.key, to: $0) },
            onToggleDetails: { tickets.toggleDetails(issue.key) },
            onToggleStar: { tickets.toggleStar(issue.key) },
            onAssignToMe: { tickets.assignToMe(issue.key) },
            onUnassign: { tickets.unassign(issue.key) },
            onWatch: { tickets.watch(issue.key) }
        )
    }

    @ViewBuilder
    private func details(for issue: TrackerIssue, now: Date) -> some View {
        if let details = tickets.details[issue.key] {
            TicketDetailsView(
                model: TicketDetailsMapper.model(for: details, ticketURL: issue.url, now: now),
                url: issue.url,
                isBusy: tickets.busyKeys.contains(issue.key),
                canAssignToMe: tickets.canAssignToMe,
                canWatch: tickets.canWatch,
                onAssignToMe: { tickets.assignToMe(issue.key) },
                onWatch: { tickets.watch(issue.key) },
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
            return ListMessage(TicketsText.emptyTitle(for: tickets.scope, includesDone: tickets.includesDone), systemImage: tickets.scope == .starred ? "star" : "ticket", description: TicketsText.emptyDescription(for: tickets.scope))
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
