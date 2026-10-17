import SwiftUI

struct ScriptRow: View {
    @Environment(ActionRunner.self) private var runner

    let action: CatalogAction

    private var slot: String { "home.scripts:\(action.id)" }

    private var chmodCommand: String {
        "chmod +x \"\(action.origin?.scriptPath ?? "")\""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                IconTile(systemImage: action.systemImage, tint: action.tint, size: 32)
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                runControls
            }
            if let pending = runner.pending(in: slot) {
                ActionPrompt(pending: pending)
            }
            ActionResultView(action: action)
        }
        .padding(.vertical, 8)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(action.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                if action.inputs.isEmpty == false {
                    Tag(action.inputs.count == 1 ? "1 input" : "\(action.inputs.count) inputs", tint: .gray)
                }
                if let layer = action.origin?.layer {
                    Tag(layer.title, tint: layer == .global ? .gray : .indigo)
                }
            }
            if action.subtitle.isEmpty == false {
                Text(action.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .hintWhenTruncated(action.subtitle)
            }
            FlowLayout(spacing: 8, lineSpacing: 2) {
                if let fileName = action.fileName {
                    Text(fileName)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                if let date = runner.lastRun(of: action) {
                    Text("Last run \(date, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let hint = action.blockedHint {
                    Tag(hint, tint: .orange, systemImage: "lock")
                        .copyOnClick(chmodCommand, label: "chmod command")
                        .hint("This file is not executable. Click to copy the command.")
                }
            }
        }
    }

    @ViewBuilder
    private var runControls: some View {
        if runner.isRunning(action) {
            ProgressView()
                .controlSize(.small)
            IconButton(systemImage: "stop.fill", help: "Stop the script", tint: .red) { runner.stop(action) }
        } else {
            Button("Run", systemImage: "play.fill") {
                runner.request(action, item: .none, slot: slot)
            }
            .controlSize(.small)
            .disabled(action.isRunnable == false)
            .fixedSize()
        }
    }
}

#Preview {
    ScriptRow(action: CatalogAction(builtin: .openFolder, title: "Example", subtitle: "A script"))
        .padding()
        .previewEnvironment()
}
