import AppKit
import UniformTypeIdentifiers

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

    @MainActor
    package static func saveFile(suggestedName: String, prompt: String, message: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        panel.prompt = prompt
        panel.message = message
        NSApp.activate()
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    @MainActor
    package static func chooseFiles(directory: URL, prompt: String, message: String, extensions: [String]) -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        panel.prompt = prompt
        panel.message = message
        panel.directoryURL = directory
        NSApp.activate()
        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }

    @MainActor
    package static func chooseFile(directory: URL, prompt: String, message: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = prompt
        panel.message = message
        panel.directoryURL = directory
        NSApp.activate()
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
