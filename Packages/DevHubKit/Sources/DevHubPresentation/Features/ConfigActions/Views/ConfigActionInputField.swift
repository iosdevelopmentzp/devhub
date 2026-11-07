import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionInputField: View {
    @Environment(BuildStore.self) private var build
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(SimulatorsStore.self) private var simulators

    let input: ActionInput
    @Binding var value: String
    let recent: RecentInputValues?

    var body: some View {
        HStack(spacing: 8) {
            Text(input.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
                .hintWhenTruncated(input.title)
            control
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var control: some View {
        switch input.type {
        case .toggle:
            Toggle("", isOn: flag)
                .labelsHidden()
        case .choice, .scheme, .branch, .worktree, .simulator:
            if choices.isEmpty {
                textField
            } else {
                SearchablePicker(title: input.title, selection: $value, items: choices, label: label, detail: { _ in nil })
            }
        case .file, .folder:
            HStack(spacing: 6) {
                textField
                Button("Choose…", action: choosePath)
                    .controlSize(.small)
                    .fixedSize()
            }
        case .text, .number:
            if let recent, recent.values.isEmpty == false {
                HStack(spacing: 4) {
                    textField
                    recentMenu(recent)
                }
            } else {
                textField
            }
        }
    }

    private func recentMenu(_ recent: RecentInputValues) -> some View {
        Menu {
            ForEach(recent.values, id: \.self) { candidate in
                Button(candidate) {
                    value = candidate
                }
            }
            Divider()
            ForEach(recent.values, id: \.self) { candidate in
                Button("Forget \(candidate)") {
                    recent.forget(candidate)
                }
            }
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .frame(width: 24, height: 24)
        .hint("Recent values")
    }

    private var flag: Binding<Bool> {
        Binding(get: { value == "true" }, set: { value = $0 ? "true" : "false" })
    }

    private var choices: [String] {
        switch input.type {
        case .choice: (input.options ?? []).map(\.value)
        case .scheme: build.schemeOptions
        case .branch: git.localBranchNames.sorted()
        case .worktree: worktrees.worktrees.map(\.path)
        case .simulator: simulators.all.sorted { $0.state == .booted && $1.state != .booted }.map(\.id)
        case .toggle, .text, .number, .file, .folder: []
        }
    }

    private var textField: some View {
        TextField(placeholder, text: $value)
            .textFieldStyle(.roundedBorder)
            .controlSize(.small)
    }

    private var placeholder: String {
        if let placeholder = input.placeholder {
            return placeholder
        }
        switch input.type {
        case .branch: return "Branch name"
        case .worktree: return "Worktree path"
        case .simulator: return "Simulator UDID"
        case .number: return "Number"
        case .file: return "File path"
        case .folder: return "Folder path"
        case .text, .toggle, .choice, .scheme: return ""
        }
    }

    private func label(_ option: String) -> String {
        guard option.isEmpty == false else { return "Choose" }
        if input.type == .simulator, let simulator = simulators.simulator(id: option) {
            return simulator.name
        }
        return input.options?.first { $0.value == option }?.label ?? option
    }

    private func choosePath() {
        let directory = URL(fileURLWithPath: value.isEmpty ? ProjectPath("~").expanded : ProjectPath(value).expanded)
        let picked = input.type == .folder
            ? FolderPicker.chooseFolder(directory: directory, prompt: "Choose", message: input.title)
            : FolderPicker.chooseFile(directory: directory, prompt: "Choose", message: input.title)
        if let picked {
            value = picked.path
        }
    }
}

#Preview {
    @Previewable @State var value = "app"
    ConfigActionInputField(
        input: ActionInput(key: "target", title: "Target", type: .choice, options: [InputOption(value: "app"), InputOption(value: "widget")]),
        value: $value,
        recent: nil
    )
    .padding()
    .previewEnvironment()
}
