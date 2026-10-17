import SwiftUI

struct ActionInputField: View {
    @Environment(ConfigStore.self) private var config
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees

    let input: ActionInput
    @Binding var value: String

    private var flag: Binding<Bool> {
        Binding(get: { value == "true" }, set: { value = $0 ? "true" : "false" })
    }

    private var choices: [String] {
        switch input.type {
        case .choice: (input.options ?? []).map(\.value)
        case .scheme: config.effective?.schemes ?? []
        case .branch: git.branchNames
        case .worktree: worktrees.worktrees.filter { $0.isMissing == false }.map(\.path)
        default: []
        }
    }

    private var pickerPrompt: String {
        input.type == .worktree ? "Choose a worktree" : "Choose a branch"
    }

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
        case .choice, .scheme, .branch, .worktree:
            if choices.isEmpty {
                textField
            } else {
                SearchablePicker(title: input.title, selection: $value, items: choices, label: optionLabel, detail: { _ in nil })
            }
        case .file, .folder:
            HStack(spacing: 6) {
                textField
                Button("Choose…", action: choosePath)
                    .controlSize(.small)
            }
        case .text, .number, .simulator:
            textField
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
        case .simulator: return "Simulator UDID (empty: none)"
        case .number: return "Number"
        case .file: return "File path"
        case .folder: return "Folder path"
        default: return ""
        }
    }

    private func optionLabel(_ option: String) -> String {
        if option.isEmpty {
            return pickerPrompt
        }
        return input.options?.first { $0.value == option }?.label ?? option
    }

    private func choosePath() {
        let picked = input.type == .folder ? FilePicker.pickFolder(message: input.title) : FilePicker.pickFile(message: input.title)
        if let picked {
            value = picked
        }
    }
}

#Preview {
    @Previewable @State var value = "App"
    ActionInputField(
        input: ActionInput(key: "target", title: "Target", type: .choice, options: [InputOption(value: "App", title: nil)], defaultValue: "App", remember: nil, placeholder: nil),
        value: $value
    )
    .padding()
    .previewEnvironment()
}
