import SwiftUI

struct ActionResultView: View {
    @Environment(ActionRunner.self) private var runner

    let action: CatalogAction

    private var result: ActionResult? {
        guard let result = runner.results[action.id] else { return nil }
        let hasView = result.view?.isEmpty == false
        return hasView || result.failureMessage != nil ? result : nil
    }

    var body: some View {
        if let result {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    content(result)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if result.isRunning == false {
                        IconButton(systemImage: "xmark", help: "Hide this result") {
                            runner.dismissResult(of: action)
                        }
                    }
                }
            }
            .padding(8)
            .background(Theme.base, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func content(_ result: ActionResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let message = result.failureMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Tint.red.color)
                    .textSelection(.enabled)
            }
            if let view = result.view {
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
    ActionResultView(action: CatalogAction(builtin: .openFolder, title: "Example", subtitle: ""))
        .padding()
        .previewEnvironment()
}
