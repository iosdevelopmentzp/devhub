import Foundation
import DevHubDomain

enum LoginShellVariablesParser {
    static let marker = "\u{1E}"

    static func script(_ names: [String]) -> String {
        let list = names.filter(isValidName).joined(separator: " ")
        return "source \"${ZDOTDIR:-$HOME}/.zshrc\" </dev/null >/dev/null 2>&1; printf '\\036'; for name in \(list); do [[ -n ${(P)name} ]] && printf '%s=%s\\0' \"$name\" \"${(P)name}\"; done; exit 0"
    }

    static func variables(in output: String, names: [String]) -> [String: String] {
        guard let range = output.range(of: marker, options: .backwards) else { return [:] }
        let allowed = Set(names)
        var variables: [String: String] = [:]
        for pair in output[range.upperBound...].split(separator: "\0") {
            guard let equals = pair.firstIndex(of: "=") else { continue }
            let name = String(pair[..<equals])
            let value = String(pair[pair.index(after: equals)...]).trimmingCharacters(in: .newlines)
            guard allowed.contains(name), value.isEmpty == false else { continue }
            variables[name] = value
        }
        return variables
    }

    static func isValidName(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) == false else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_")
        return name.unicodeScalars.allSatisfy(allowed.contains)
    }
}
