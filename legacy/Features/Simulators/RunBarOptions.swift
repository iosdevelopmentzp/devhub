import SwiftUI

struct RunBarOptions: View {
    @Environment(BuildStore.self) private var build

    private var scheme: Binding<String> {
        Binding(get: { build.scheme }, set: { value in build.setOptions { $0.scheme = value } })
    }

    private var configuration: Binding<String> {
        Binding(get: { build.configuration }, set: { value in build.setOptions { $0.configuration = value } })
    }

    private var source: Binding<BuildSource> {
        Binding(get: { build.source }, set: { build.chooseSource($0) })
    }

    private var fast: Binding<Bool> {
        Binding(get: { build.options.fast }, set: { value in build.setOptions { $0.fast = value } })
    }

    private var cleanInstall: Binding<Bool> {
        Binding(get: { build.options.cleanInstall }, set: { value in build.setOptions { $0.cleanInstall = value } })
    }

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 6) {
            if build.isCommandProject == false {
                SearchablePicker(title: "Scheme", selection: scheme, items: build.schemes) { _ in nil }
                SearchablePicker(title: "Configuration", selection: configuration, items: build.configurationChoices) { _ in nil }
            }
            sourcePicker
            Toggle("Fast", isOn: fast)
                .toggleStyle(.checkbox)
                .hint("Skip xcodebuild clean before the build")
            Toggle("Clean install", isOn: cleanInstall)
                .toggleStyle(.checkbox)
                .hint("Delete the app and reset the simulator keychain before installing")
            IconButton(systemImage: "arrow.clockwise", help: "Reload the build source list and the configurations") {
                Task {
                    await build.worktrees.refreshCheckouts()
                    await build.loadConfigurations()
                }
            }
        }
        .controlSize(.small)
    }

    private var sourcePicker: some View {
        SearchablePicker(
            title: "Build source",
            selection: source,
            items: build.sourceChoices,
            label: { build.title(of: $0) },
            detail: { _ in nil }
        )
        .trigger { choice in
            AnyView(
                HStack(spacing: 4) {
                    Image(systemName: icon(of: choice))
                        .foregroundStyle(Tint.indigo.color)
                    Text(build.title(of: choice))
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 6))
            )
        }
    }

    private func icon(of source: BuildSource) -> String {
        switch source {
        case .main: "house"
        case .worktree: "square.stack.3d.up"
        case .branch: "arrow.triangle.branch"
        }
    }
}

#Preview {
    RunBarOptions()
        .padding()
        .previewEnvironment()
}
