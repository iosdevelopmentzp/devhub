import AppKit

package enum FolderPicker {

    @MainActor
    package static func chooseFolder(directory: URL, prompt: String, message: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = prompt
        panel.message = message
        panel.directoryURL = directory
        NSApp.activate()
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
