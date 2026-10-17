import AppKit

@MainActor
enum FilePicker {
    static func pickFolder(message: String) -> String? {
        pick(message: message, canChooseFiles: false, canChooseDirectories: true)
    }

    static func pickFile(message: String) -> String? {
        pick(message: message, canChooseFiles: true, canChooseDirectories: false)
    }

    private static func pick(message: String, canChooseFiles: Bool, canChooseDirectories: Bool) -> String? {
        let panel = NSOpenPanel()
        panel.message = message
        panel.canChooseFiles = canChooseFiles
        panel.canChooseDirectories = canChooseDirectories
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return nil }
        return panel.url?.path
    }
}
