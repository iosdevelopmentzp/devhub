import SwiftUI
import DevHubDomain
import DevHubUI

struct MockServerBar: View {
    @Environment(NetworkStore.self) private var network
    @Environment(MockServerStore.self) private var mockServer
    @Environment(MockSetsStore.self) private var mockSets
    @Environment(IdentityStore.self) private var identityStore

    var body: some View {
        ToolbarBar {
            content
        }
    }

    private var content: some View {
        @Bindable var mockSets = mockSets
        let model = model
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Picker("Network mode", selection: modeBinding) {
                    ForEach(model.modes) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .disabled(network.selectedUDID == nil)
                .hint("Off: the app talks to its real hosts. Passthrough: DevHub forwards every request and shows it with exact timing. Mock: rules from the set answer first, the rest is forwarded.")
                if model.showsSetPicker {
                    Picker("Mock set", selection: setBinding) {
                        Text("Choose a set").tag(MockSet.ID?.none)
                        ForEach(model.sets) { option in
                            Text(option.title).tag(MockSet.ID?.some(option.id))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .hint("The rules of this set answer matching requests")
                }
                Toggle(isOn: $mockSets.isShowingRules) {
                    Label("Rules", systemImage: "list.bullet.rectangle")
                }
                .toggleStyle(.button)
                .fixedSize()
                .hint("Edit mock sets and their rules")
                Spacer(minLength: 6)
                applyButton(model)
            }
            HStack(spacing: 6) {
                StatusDot(color: model.statusTint.color)
                Text(model.statusText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .hint(model.statusHint)
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .hint(MockServerBarModel.limitsHint)
                Spacer(minLength: 0)
            }
            if let appText = model.appText {
                HStack(spacing: 6) {
                    StatusDot(color: model.appTint.color)
                    Text(appText)
                        .font(.caption)
                        .foregroundStyle(model.appTint == .orange ? Color.orange : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hint(model.appHint)
                    Spacer(minLength: 0)
                }
            }
            if let error = model.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func applyButton(_ model: MockServerBarModel) -> some View {
        let button = Button(model.applyTitle, systemImage: "arrow.clockwise") {
            guard let udid = network.selectedUDID else { return }
            mockServer.apply(on: udid)
        }
        .fixedSize()
        .disabled(model.canApply == false)
        .hint("Stop the app and launch it again with the chosen network mode. The app reads the server address only at launch.")
        if model.isApplyProminent {
            button.buttonStyle(.borderedProminent)
        } else {
            button
        }
    }

    private var modeBinding: Binding<MockMode> {
        Binding(
            get: { network.selectedUDID.map { mockServer.settings(for: $0).mode } ?? .off },
            set: { mode in
                guard let udid = network.selectedUDID else { return }
                mockServer.setMode(mode, for: udid)
            }
        )
    }

    private var setBinding: Binding<MockSet.ID?> {
        Binding(
            get: { network.selectedUDID.flatMap { mockServer.settings(for: $0).setID } },
            set: { setID in
                guard let udid = network.selectedUDID else { return }
                mockServer.selectSet(setID, for: udid)
            }
        )
    }

    private var model: MockServerBarModel {
        let udid = network.selectedUDID
        return MockServerBarMapper.model(
            settings: udid.map { mockServer.settings(for: $0) } ?? .off,
            state: udid.flatMap { mockServer.states[$0] },
            sets: mockSets.sets,
            hasSimulator: udid != nil,
            isApplying: udid.map(mockServer.isApplying) ?? false,
            needsApply: udid.map(mockServer.needsApply) ?? false,
            error: udid.flatMap { mockServer.errors[$0] },
            identity: udid.flatMap { identityStore.identities[$0] },
            config: identityStore.config
        )
    }
}

#Preview {
    MockServerBar()
        .previewEnvironment()
        .frame(width: 720)
}
