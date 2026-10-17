import Foundation

nonisolated enum TerminalScript {
    static func build(command: String, cwd: String) -> String {
        let escapedCommand = escapeForDoubleQuotes(command)
        return """
        #!/bin/zsh
        rm -f "$0"
        cd \(singleQuoted(cwd)) || exit 1
        exec "${SHELL:-/bin/zsh}" -i -l -c "\(escapedCommand); exec \\"${SHELL:-/bin/zsh}\\" -i -l"

        """
    }

    private static func singleQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func escapeForDoubleQuotes(_ value: String) -> String {
        var result = ""
        for character in value {
            if "\\\"$`".contains(character) {
                result.append("\\")
            }
            result.append(character)
        }
        return result
    }
}
