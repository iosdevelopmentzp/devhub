import Foundation
import DevHubDomain
import DevHubUI

enum AppDataPanelMapper {
    static let rowLimit = 60

    static func model(for data: AppData, query: String) -> AppDataPanelModel {
        AppDataPanelModel(
            title: "App data of \(data.bundleID)",
            containerPath: data.container,
            containerText: data.container.abbreviatingHome,
            folders: data.folders.map { fileRow($0, icon: "folder", hint: "Show in Finder") }
                + data.groups.map { fileRow($0, icon: "folder.badge.person.crop", hint: "App group container. Show in Finder") },
            databases: data.databases.map { fileRow($0, icon: "cylinder.split.1x2", hint: "Show in Finder") },
            databasesEmptyText: "No .sqlite, .db, .store or .realm files",
            sections: data.suites.map { section($0, query: query) },
            resetConfirmation: "Reset the data of \(data.bundleID)?",
            resetWarnings: [
                "Stops the app.",
                "Deletes Documents, Library and tmp: files, databases, caches and user defaults.",
                "Keychain items stay.",
            ],
            groupsToggleTitle: groupsToggleTitle(data.groups),
            footnote: "A running app reads changed keys after a relaunch."
        )
    }

    static func section(_ suite: AppDefaultsSuite, query: String) -> AppDefaultsSectionModel {
        let matching = suite.entries.filter { AppDefaultsPolicy.matches($0, query: query) }
        let shown = matching.prefix(rowLimit)
        let hidden = matching.count - shown.count
        let isFiltered = matching.count != suite.entries.count
        return AppDefaultsSectionModel(
            id: suite.id,
            suite: suite,
            title: "User defaults · \(suite.name)",
            detail: isFiltered ? "\(matching.count) of \(CountText.count(suite.entries.count, "key"))" : CountText.count(suite.entries.count, "key"),
            rows: shown.map(row),
            hiddenText: hidden > 0 ? "\(CountText.count(hidden, "more key")). Search to narrow the list." : nil,
            emptyText: emptyText(suite: suite, matching: matching, query: query)
        )
    }

    static func row(_ entry: AppDefault) -> AppDefaultRowModel {
        let canEdit = AppDefaultsPolicy.isEditable(entry.kind)
        let toggleValue = AppDefaultsPolicy.toggled(entry)
        return AppDefaultRowModel(
            id: entry.id,
            key: entry.key,
            kind: entry.kind,
            kindTag: TagModel(kindTitle(entry.kind), tint: .secondary),
            valueText: entry.text.isEmpty ? "\"\"" : entry.text,
            editText: entry.text,
            canEdit: canEdit,
            toggleValue: toggleValue,
            toggleHint: toggleValue.map(toggleHint),
            readOnlyHint: canEdit ? nil : "DevHub edits strings, numbers and booleans. Change a \(kindTitle(entry.kind)) value in the app or with defaults."
        )
    }

    static func kindTitle(_ kind: AppDefault.Kind) -> String {
        switch kind {
        case .string: "string"
        case .integer: "int"
        case .float: "float"
        case .bool: "bool"
        case .date: "date"
        case .data: "data"
        case .array: "array"
        case .dictionary: "dict"
        }
    }

    private static func fileRow(_ file: AppDataFile, icon: String, hint: String) -> AppDataFileRowModel {
        AppDataFileRowModel(id: file.id, name: file.name, path: file.path, sizeText: ByteFormat.text(file.size), icon: icon, hint: hint)
    }

    private static func groupsToggleTitle(_ groups: [AppDataFile]) -> String? {
        guard groups.isEmpty == false else { return nil }
        return "Also clear the app group containers (\(groups.map(\.name).joined(separator: ", ")))"
    }

    private static func toggleHint(_ value: AppDefaultValue) -> String {
        guard case .bool(let flag) = value else { return "" }
        return "Set to \(flag ? "true" : "false")"
    }

    private static func emptyText(suite: AppDefaultsSuite, matching: [AppDefault], query: String) -> String? {
        guard matching.isEmpty else { return nil }
        return suite.entries.isEmpty ? "No keys yet" : "No key matches \"\(query.trimmingCharacters(in: .whitespaces))\""
    }
}
