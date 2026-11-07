import SwiftUI
import DevHubDomain
import DevHubUI

struct CustomTabSourceSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigActionsStore.self) private var store
    @Environment(\.panelOpenCount) private var openCount

    let title: String
    let action: ResolvedAction
    let refresh: TabRefresh
    let item: ActionItemContext

    var body: some View {
        let run = store.runs[action.id]
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title) {
                HStack(spacing: 6) {
                    if store.isRunning(action.id) {
                        ProgressView()
                            .controlSize(.small)
                    } else if let date = store.lastRun(of: action.id) {
                        Text("read \(date.relativeDescription)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    IconButton(systemImage: "arrow.clockwise", help: "Run \(action.origin.fileName) again") {
                        reload()
                    }
                    .disabled(store.isRunning(action.id))
                }
            }
            PanelCard {
                content(run)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: openCount) {
            await autoRefresh()
        }
    }

    @ViewBuilder
    private func content(_ run: ConfigActionRun?) -> some View {
        if let message = run?.failureMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(Tint.red.color)
                .textSelection(.enabled)
        } else if let view = run?.view, view.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                if view.pairs.isEmpty == false {
                    KeyValueBlock(pairs: view.pairs)
                }
                if let text = view.text, text.isEmpty == false {
                    Text(text)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                ForEach(rows(of: view)) { row in
                    ScriptViewRowView(parent: action, row: row)
                }
            }
        } else {
            Text(store.isRunning(action.id) ? "Running \(action.origin.fileName)…" : emptyText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyText: String {
        refresh == .manual ? "Press refresh to run \(action.origin.fileName)." : "\(action.origin.fileName) printed no view line."
    }

    private func rows(of view: ScriptView) -> [ScriptViewRow] {
        (view.rows ?? []).filter { row in
            session.matchesSearch(row.title, row.subtitle ?? "", (row.tags ?? []).map(\.text).joined(separator: " "))
        }
    }

    private func reload() {
        store.runWithDefaults(action, item: item)
    }

    private func autoRefresh() async {
        switch refresh {
        case .manual:
            return
        case .onOpen:
            reload()
        case .every(let seconds):
            while Task.isCancelled == false {
                if store.isRunning(action.id) == false {
                    reload()
                }
                try? await Task.sleep(for: .seconds(seconds))
            }
        }
    }
}

#Preview {
    CustomTabSourceSection(
        title: "Devices",
        action: ResolvedAction(
            config: ActionConfig(id: "script:list-devices", title: "list-devices", run: .script("scripts/list-devices.sh")),
            origin: ActionOrigin(layer: .project, directory: "/repo/.devhub", fileName: "scripts/list-devices.sh", isHeaderScript: true, isExecutable: true)
        ),
        refresh: .manual,
        item: .none
    )
    .padding()
    .previewEnvironment()
}
