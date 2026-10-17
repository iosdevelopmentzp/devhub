import SwiftUI

struct RunBarButtons: View {
    @Environment(BuildStore.self) private var build
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner

    private var canRun: Bool { build.target != nil && build.isRunning == false }

    private var context: ActionItemContext {
        ActionItemContext(simulatorUDID: build.target?.id, simulatorName: build.target?.name)
    }

    var body: some View {
        HStack(spacing: 8) {
            ActionBar(items: items)
            Spacer(minLength: 8)
            if build.isRunning {
                Button("Cancel", systemImage: "stop.fill") { build.cancel() }
                    .controlSize(.regular)
                    .fixedSize()
                    .hint("Stop the build")
            } else {
                Button {
                    build.start(.buildRun)
                } label: {
                    Label("Build & Run", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(canRun == false)
                .fixedSize()
                .hint("Build the project and launch it on the target")
            }
        }
    }

    private var items: [ActionItem] {
        let bar = [
            ActionItem("Run & Attach", systemImage: "ladybug", hint: "Build, launch and attach the Xcode debugger", priority: 1, isDisabled: canRun == false) {
                build.start(.runAttach)
            },
            ActionItem("Launch", systemImage: "arrow.up.forward.app", hint: "Launch the installed app without building", priority: 2, isDisabled: canRun == false) {
                build.start(.launch)
            }
        ]
        return bar + catalog.actions(for: .simulatorsRunBar).map { action in
            ActionItem(action.title, systemImage: action.systemImage, hint: action.subtitle.isEmpty ? action.title : action.subtitle, priority: 3, isDisabled: runner.isRunning(action)) {
                runner.request(action, item: context, slot: RunBarCard.slot)
            }
        }
    }
}

#Preview {
    RunBarButtons()
        .padding()
        .previewEnvironment()
}
