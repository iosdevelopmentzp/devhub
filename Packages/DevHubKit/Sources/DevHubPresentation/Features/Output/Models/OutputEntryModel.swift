import Foundation
import DevHubDomain
import DevHubUI

struct OutputEntryModel: Identifiable, Equatable {
    let id: UUID
    var command: String
    var commandLine: String
    var folder: String?
    var folderPath: String?
    var startedText: String
    var durationText: String
    var isRunning: Bool
    var statusIcon: String
    var statusTint: Tint
    var statusHint: String?
    var isExpanded: Bool
    var canExpand: Bool
    var expandIcon: String
    var expandHint: String
    var output: String?
    var fullOutput: String?
    var outputTint: Tint?
    var error: String?

    static let preview = OutputEntryModel(
        id: UUID(),
        command: "git -C ~/Projects/ExampleApp fetch --prune",
        commandLine: "$ git -C ~/Projects/ExampleApp fetch --prune",
        folder: "~/Projects/ExampleApp",
        folderPath: "/Users/alex/Projects/ExampleApp",
        startedText: "14:05:09",
        durationText: "1.4 s",
        isRunning: false,
        statusIcon: "xmark.circle.fill",
        statusTint: .red,
        statusHint: "Exit code 128",
        isExpanded: false,
        canExpand: true,
        expandIcon: "chevron.down",
        expandHint: "Show all 12 lines",
        output: "… 4 more lines above\nfatal: unable to access 'https://gitlab.example.com/top/live.git/'",
        fullOutput: "fatal: unable to access 'https://gitlab.example.com/top/live.git/'",
        outputTint: .red,
        error: nil
    )
}
