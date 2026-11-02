import AppKit
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class WorkspaceActions {
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let opener: any WorkspaceOpening
    @ObservationIgnored private let files: any TextFileRepository

    init(settings: SettingsStore, activity: ActivityLog, opener: any WorkspaceOpening, files: any TextFileRepository) {
        self.settings = settings
        self.activity = activity
        self.opener = opener
        self.files = files
    }

    func openTerminal(at path: String) {
        let app = settings.values.terminal
        Task { [weak self, opener] in
            let failure = await opener.openTerminal(app, at: path)
            guard let self else { return }
            if let failure {
                activity.log("Could not open \(app)", detail: failure, outcome: .failure)
            } else {
                activity.log("Opened \(app)", detail: path, outcome: .info)
            }
        }
    }

    func runInTerminal(_ command: String, at path: String, title: String) {
        let app = settings.values.terminal
        Task { [weak self, opener] in
            let failure = await opener.runInTerminal(app, at: path, command: command)
            guard let self else { return }
            if let failure {
                activity.log("Could not open \(app)", detail: failure, outcome: .failure)
            } else {
                activity.log(title, detail: path.abbreviatingHome, outcome: .info)
            }
        }
    }

    func openInFinder(path: String) {
        NSWorkspace.shared.open(ProjectPath(path).url)
    }

    func revealInFinder(path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([ProjectPath(path).url])
    }

    func openWithDefaultApp(path: String) {
        NSWorkspace.shared.open(ProjectPath(path).url)
    }

    func openInXcode(path: String, container: String?) {
        Task { [weak self, opener] in
            let failure = await opener.openInXcode(path, container: container)
            guard let self, let failure else { return }
            activity.log("Could not open Xcode", detail: failure, outcome: .failure)
        }
    }

    func openFile(path: String, line: Int?) {
        Task { [weak self, opener] in
            guard let self else { return }
            let editor = settings.values.editor
            guard let failure = await opener.openFile(path, line: line, editor: editor) else { return }
            activity.log("Could not open the file in \(editor)", detail: failure, outcome: .failure)
        }
    }

    func openInEditor(path: String, editor: String) {
        Task { [weak self, opener] in
            let failure = await opener.openInEditor(editor, path: path)
            guard let self, let failure else { return }
            activity.log("Could not open \(editor)", detail: failure, outcome: .failure)
        }
    }

    func openInEditor(text: String, name: String) {
        Task { [weak self, files] in
            guard let self else { return }
            do {
                let path = try await files.writeScratch(text, name: name)
                openFile(path: path, line: nil)
            } catch {
                activity.log("Could not write \(name)", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func saveText(_ text: String, to path: String) {
        Task { [weak self, files] in
            guard let self else { return }
            do {
                try await files.write(text, to: path)
                activity.log("Saved \((path as NSString).lastPathComponent)", detail: path.abbreviatingHome, outcome: .success)
            } catch {
                activity.log("Could not save \((path as NSString).lastPathComponent)", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func openTarget(_ target: String, relativeTo folder: String) -> Bool {
        let trimmed = target.trimmed
        guard trimmed.isEmpty == false else { return false }
        if let url = URL(string: trimmed), let scheme = url.scheme, scheme.count > 1 {
            return NSWorkspace.shared.open(url)
        }
        let path = trimmed.hasPrefix("/") ? trimmed : trimmed.hasPrefix("~") ? ProjectPath(trimmed).expanded : folder + "/" + trimmed
        guard FileManager.default.fileExists(atPath: path) else {
            activity.log("Could not open \(trimmed)", detail: "\(path) does not exist.", outcome: .failure)
            return false
        }
        return NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func open(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}
