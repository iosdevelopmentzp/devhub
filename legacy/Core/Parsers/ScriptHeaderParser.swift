import Foundation

nonisolated struct ScriptHeaderResult: Sendable {
    var action: ActionConfig
    var problems: [String]
    var hasHeader: Bool
}

nonisolated enum ScriptHeaderParser {
    static let maxLines = 20
    private static let prefix = "devhub:"

    static func parse(_ text: String, relativePath: String) -> ScriptHeaderResult {
        let base = fileBaseName(relativePath)
        var action = ActionConfig(id: "script:\(base)", title: base, run: .script(relativePath))
        var problems: [String] = []
        var hasHeader = false
        var inputs: [ActionInput] = []
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).prefix(maxLines)
        for line in lines {
            guard let (key, value) = field(in: String(line)) else { continue }
            hasHeader = true
            apply(key: key, value: value, to: &action, inputs: &inputs, problems: &problems)
        }
        if inputs.isEmpty == false {
            action.inputs = inputs
        }
        return ScriptHeaderResult(action: action, problems: problems, hasHeader: hasHeader)
    }

    static func hasShebang(_ text: String) -> Bool {
        text.hasPrefix("#!")
    }

    static func fileBaseName(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        return name.isEmpty ? path : name
    }

    private static func field(in line: String) -> (String, String)? {
        var rest = line.trimmingCharacters(in: .whitespaces)
        guard rest.hasPrefix("#") else { return nil }
        rest = String(rest.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard rest.hasPrefix(prefix) else { return nil }
        rest = String(rest.dropFirst(prefix.count))
        guard let separator = rest.firstIndex(of: "=") else { return nil }
        let key = rest[..<separator].trimmingCharacters(in: .whitespaces).lowercased()
        let value = rest[rest.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        return (key, value)
    }

    private static func apply(key: String, value: String, to action: inout ActionConfig, inputs: inout [ActionInput], problems: inout [String]) {
        switch key {
        case "title": action.title = value
        case "subtitle": action.subtitle = value
        case "icon": action.icon = value
        case "confirm": action.confirm = value
        case "cwd": action.cwd = value
        case "tint":
            if let tint = Tint(rawValue: value.lowercased()) {
                action.tint = tint
            } else {
                problems.append("tint \"\(value)\" is not a known colour.")
            }
        case "placements":
            action.placements = list(value).map(Placement.init)
        case "refresh":
            action.refresh = list(value).compactMap { name in
                guard let target = RefreshTarget(rawValue: name) else {
                    problems.append("refresh \"\(name)\" is not a known store.")
                    return nil
                }
                return target
            }
        case "input":
            if let input = parseInput(value) {
                inputs.append(input)
            } else {
                problems.append("input \"\(value)\" needs: key, title, type, default or options.")
            }
        default:
            problems.append("unknown header key \"\(key)\".")
        }
    }

    private static func list(_ value: String) -> [String] {
        value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }
    }

    private static func parseInput(_ value: String) -> ActionInput? {
        let parts = value.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 3, parts[0].isEmpty == false, let type = InputType(rawValue: parts[2].lowercased()) else { return nil }
        let rest = parts.count > 3 ? parts[3] : ""
        var input = ActionInput(key: parts[0], title: parts[1].isEmpty ? parts[0] : parts[1], type: type, options: nil, defaultValue: nil, remember: nil, placeholder: nil)
        if type == .choice {
            let options = rest.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }
            input.options = options.map { InputOption(value: $0, title: nil) }
            input.defaultValue = options.first
        } else if rest.isEmpty == false {
            input.defaultValue = rest
        }
        return input
    }
}
