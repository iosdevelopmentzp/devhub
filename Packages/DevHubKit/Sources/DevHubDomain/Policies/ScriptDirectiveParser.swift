import Foundation

package enum ScriptDirectiveParser {
    package static let marker = "@devhub "

    package static func parse(_ line: String) -> ScriptLine {
        guard line.hasPrefix(marker) else { return .plain }
        let json = String(line.dropFirst(marker.count))
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .invalid("The directive is not one JSON object.")
        }
        var directives: [ScriptDirective] = []
        if let text = object["progress"] as? String {
            directives.append(.progress(text: text, fraction: (object["fraction"] as? NSNumber)?.doubleValue))
        }
        if let text = object["toast"] as? String {
            directives.append(.toast(text))
        }
        if let text = object["copy"] as? String {
            directives.append(.copy(text))
        }
        if let target = object["open"] as? String {
            directives.append(.open(target))
        }
        if let title = object["notify"] as? String {
            directives.append(.notify(title: title, body: object["body"] as? String))
        }
        if let names = object["refresh"] as? [String] {
            directives.append(.refresh(names.compactMap(RefreshTarget.init(rawValue:))))
        }
        if let message = object["error"] as? String {
            directives.append(.error(message))
        }
        if let path = object["app"] as? String {
            directives.append(.app(path))
        }
        if let raw = object["view"] {
            switch decodeView(raw) {
            case let .success(view): directives.append(.view(view))
            case let .failure(message): return .invalid(message)
            }
        }
        return directives.isEmpty ? .unknown : .directives(directives)
    }

    private enum ViewResult {
        case success(ScriptView)
        case failure(String)
    }

    private static func decodeView(_ raw: Any) -> ViewResult {
        guard JSONSerialization.isValidJSONObject(raw), let data = try? JSONSerialization.data(withJSONObject: raw) else {
            return .failure("The view is not a JSON object.")
        }
        do {
            return .success(try JSONDecoder().decode(ScriptView.self, from: data))
        } catch {
            return .failure("The view is not valid: \(ConfigDecoding.describe(error)).")
        }
    }
}
