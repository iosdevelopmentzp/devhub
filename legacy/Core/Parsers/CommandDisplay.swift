import Foundation

nonisolated enum CommandDisplay {
    private static let plainCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./=:,@+%~")

    static func format(executable: String, arguments: [String]) -> String {
        ([executable] + arguments).map(quote).joined(separator: " ")
    }

    private static func quote(_ argument: String) -> String {
        if argument.contains("\n") {
            return "'…script…'"
        }
        guard argument.isEmpty == false else { return "''" }
        if argument.unicodeScalars.allSatisfy({ plainCharacters.contains($0) }) {
            return argument
        }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
