import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionResultView: View {
    @Environment(ConfigActionsStore.self) private var store

    let action: ResolvedAction

    var body: some View {
        if let run = visibleRun {
            HStack(alignment: .top, spacing: 6) {
                content(run)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if run.isRunning == false {
                    IconButton(systemImage: "xmark", help: "Hide this result") {
                        store.dismissResult(of: action.id)
                    }
                }
            }
            .padding(8)
            .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var visibleRun: ConfigActionRun? {
        guard let run = store.runs[action.id] else { return nil }
        return run.view?.isEmpty == false ? run : nil
    }

    private func content(_ run: ConfigActionRun) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let view = run.view {
                if view.pairs.isEmpty == false {
                    KeyValueBlock(pairs: view.pairs)
                }
                if let text = view.text, text.isEmpty == false {
                    Text(text)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                ForEach(view.rows ?? []) { row in
                    ScriptViewRowView(parent: action, row: row)
                }
            }
        }
    }
}

#Preview {
    ConfigActionResultView(action: ResolvedAction(
        config: ActionConfig(id: "x", title: "Example", run: .open("x")),
        origin: ActionOrigin(layer: .project, directory: "/repo/.devhub", fileName: "actions/x.json", isHeaderScript: false, isExecutable: true)
    ))
    .padding()
    .previewEnvironment()
}
