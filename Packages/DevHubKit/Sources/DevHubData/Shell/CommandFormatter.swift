import Foundation
import DevHubDomain

enum CommandFormatter {

    static let maxArgumentLength = 160

    static func displayCommand(_ executable: String, _ arguments: [String]) -> String {
        ([executable] + arguments.map { quoted(shortened($0)) }).joined(separator: " ")
    }

    private static func shortened(_ argument: String) -> String {
        guard argument.count > maxArgumentLength else { return argument }
        return argument.prefix(maxArgumentLength) + "…"
    }

    private static func quoted(_ argument: String) -> String {
        guard argument.isEmpty || argument.contains(where: { $0.isWhitespace || "'\"$`\\\\".contains($0) }) else { return argument }
        if argument.contains("\n") { return "'…script…'" }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
