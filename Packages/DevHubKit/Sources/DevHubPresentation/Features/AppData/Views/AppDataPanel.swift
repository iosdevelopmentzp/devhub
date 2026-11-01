import SwiftUI
import DevHubDomain
import DevHubUI

struct AppDataPanel: View {
    @Environment(AppDataStore.self) private var store
    @Environment(AppActions.self) private var appActions

    let simulator: Simulator
    let bundleID: String
    let onClose: () -> Void

    @State private var query = ""
    @State private var addingSuiteID: AppDefaultsSuite.ID?
    @State private var isConfirmingReset = false
    @State private var includesGroups = false

    private var isBooted: Bool {
        simulator.state == .booted
    }

    private var model: AppDataPanelModel? {
        store.data[simulator.id].map { AppDataPanelMapper.model(for: $0, query: query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ConfigActionBar(
                placement: .simulatorsAppData,
                item: ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name, bundleID: bundleID, rowID: simulator.id, refresh: [.appData])
            )
            OperationSlot(origin: .simulator(simulator.id))
            if isBooted == false {
                message("Boot the simulator first. DevHub reads the app data through the running simulator.", tint: .orange)
            } else if let error = store.errors[simulator.id] {
                NoticeBar(error, actionTitle: "Retry") { reload() }
            } else if let model {
                content(model)
            } else {
                message("Reading the app data…", tint: .secondary)
            }
        }
        .controlSize(.small)
        .padding(10)
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .animation(.snappy(duration: 0.18), value: isConfirmingReset)
        .animation(.snappy(duration: 0.18), value: addingSuiteID)
        .task(id: "\(simulator.state)-\(bundleID)") {
            guard isBooted else { return }
            await store.load(simulatorID: simulator.id, bundleID: bundleID)
        }
        .onDisappear {
            store.forget(simulatorID: simulator.id)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "externaldrive")
                .foregroundStyle(.secondary)
            Text(model?.title ?? "App data of \(bundleID)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if store.isBusy(simulator.id) {
                ProgressView()
                    .controlSize(.small)
            }
            IconButton(systemImage: "arrow.clockwise", help: "Read the app data again") { reload() }
                .disabled(isBooted == false || store.isBusy(simulator.id))
            Button("Close", action: onClose)
                .fixedSize()
        }
    }

    private func content(_ model: AppDataPanelModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                FieldLabel("Container")
                Text(model.containerText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .copyOnClick(model.containerPath, label: "Container path")
                Spacer(minLength: 4)
                IconButton(systemImage: "folder", help: "Show the data container in Finder") {
                    appActions.openInFinder(path: model.containerPath)
                }
            }

            ListSectionHeader("Folders", systemImage: "folder", topPadding: 6)
            ForEach(model.folders) { AppDataFileRow(model: $0) }

            ListSectionHeader("Databases", systemImage: "cylinder.split.1x2", topPadding: 6)
            if model.databases.isEmpty {
                message(model.databasesEmptyText, tint: .secondary)
                    .padding(.horizontal, 14)
            }
            ForEach(model.databases) { AppDataFileRow(model: $0) }

            TextField("Filter keys and values", text: $query)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .padding(.top, 8)
            ForEach(model.sections) { section($0) }

            reset(model)
                .padding(.top, 8)
            message(model.footnote, tint: .secondary)
        }
    }

    private func section(_ section: AppDefaultsSectionModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ListSectionHeader(section.title, systemImage: "list.bullet.rectangle", detail: section.detail, topPadding: 8) {
                Button("Add Key", systemImage: "plus") { addingSuiteID = section.id }
                    .buttonStyle(LinkButtonStyle(.accent))
                    .disabled(store.isBusy(simulator.id))
            }
            if addingSuiteID == section.id {
                AppDefaultAddForm(
                    suite: section.suite,
                    onAdd: { key, value in
                        addingSuiteID = nil
                        store.write(value, key: key, in: section.suite, simulatorID: simulator.id)
                    },
                    onCancel: { addingSuiteID = nil }
                )
            }
            ForEach(section.rows) { row in
                AppDefaultRow(
                    model: row,
                    isDisabled: store.isBusy(simulator.id),
                    onSave: { store.write($0, key: row.key, in: section.suite, simulatorID: simulator.id) },
                    onDelete: { store.delete(key: row.key, in: section.suite, simulatorID: simulator.id) }
                )
            }
            if let emptyText = section.emptyText {
                message(emptyText, tint: .secondary)
                    .padding(.horizontal, 14)
            }
            if let hiddenText = section.hiddenText {
                message(hiddenText, tint: .secondary)
                    .padding(.horizontal, 14)
            }
        }
    }

    @ViewBuilder
    private func reset(_ model: AppDataPanelModel) -> some View {
        if isConfirmingReset {
            InlineConfirmation(
                model.resetConfirmation,
                confirmTitle: "Reset",
                confirmRole: .destructive,
                layout: .stacked(warnings: model.resetWarnings),
                onCancel: { isConfirmingReset = false },
                onConfirm: {
                    isConfirmingReset = false
                    store.reset(simulatorID: simulator.id, includingGroups: includesGroups)
                }
            ) {
                if let title = model.groupsToggleTitle {
                    Toggle(title, isOn: $includesGroups)
                        .font(.caption)
                }
            }
        } else {
            Button("Reset App Data…", systemImage: "arrow.counterclockwise", role: .destructive) {
                isConfirmingReset = true
            }
            .fixedSize()
            .disabled(store.isBusy(simulator.id))
        }
    }

    private func message(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(tint)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func reload() {
        Task { await store.load(simulatorID: simulator.id, bundleID: bundleID) }
    }
}

#Preview {
    AppDataPanel(simulator: Simulator(id: "preview", name: "iPhone 17", kind: .phone, state: .booted, isFavorite: false), bundleID: "com.example.app", onClose: {})
        .previewEnvironment()
        .padding()
        .frame(width: 680)
}
