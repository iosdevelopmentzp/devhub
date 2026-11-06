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
        if let state = object["state"] as? [String: Any] {
            switch stateReport(state) {
            case let .success(report): directives.append(.state(report))
            case let .failure(failure): return .invalid(failure.message)
            }
        }
        if let raw = object["view"] {
            switch decode(raw, as: ScriptView.self, subject: "The view is", shape: "a JSON object") {
            case let .success(view): directives.append(.view(view))
            case let .failure(failure): return .invalid(failure.message)
            }
        }
        return directives.isEmpty ? .unknown : .directives(directives)
    }

    private static func stateReport(_ object: [String: Any]) -> Result<AppStateReport, DecodeFailure> {
        func text(_ key: String) -> String? {
            guard let value = (object[key] as? String)?.trimmed, value.isEmpty == false else { return nil }
            return value
        }
        var report = AppStateReport(identity: text("identity"), profile: text("profile"), host: text("host"), user: text("user"), version: text("version"))
        guard let raw = object["tags"] else { return .success(report) }
        switch decode(raw, as: [ScriptViewTag].self, subject: "The state tags are", shape: "a JSON list") {
        case let .success(tags):
            report.tags = tags.filter { $0.text.trimmed.isEmpty == false }
            return .success(report)
        case let .failure(failure):
            return .failure(failure)
        }
    }

    private struct DecodeFailure: Error {
        let message: String
    }

    private static func decode<Value: Decodable>(_ raw: Any, as type: Value.Type, subject: String, shape: String) -> Result<Value, DecodeFailure> {
        guard JSONSerialization.isValidJSONObject(raw), let data = try? JSONSerialization.data(withJSONObject: raw) else {
            return .failure(DecodeFailure(message: "\(subject) not \(shape)."))
        }
        do {
            return .success(try JSONDecoder().decode(type, from: data))
        } catch {
            return .failure(DecodeFailure(message: "\(subject) not valid: \(ConfigDecoding.describe(error))."))
        }
    }
}
