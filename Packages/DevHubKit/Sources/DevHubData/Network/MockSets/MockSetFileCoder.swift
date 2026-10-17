import Foundation
import DevHubDomain

enum MockSetFileCoder {
    struct Encoded {
        var json: Data
        var bodies: [String: Data]
    }

    static let inlineBodyLimit = 1_024

    static func encode(_ set: MockSet, bodyFolder: String) throws -> Encoded {
        var bodies: [String: Data] = [:]
        let rules = set.rules.map { rule -> [String: Any] in
            var object: [String: Any] = ["id": rule.id.uuidString, "enabled": rule.isEnabled, "path": rule.pathPattern]
            object["method"] = rule.method
            object["query"] = rule.query
            switch rule.action {
            case .respond(let response):
                var respond: [String: Any] = [
                    "status": response.status,
                    "delay": response.delay,
                    "headers": headers(response.headers)
                ]
                let body = LogRedactor.redact(response.body)
                if body.count > inlineBodyLimit {
                    let file = uniqueName(MockRouteName.fileName(method: rule.method, path: rule.pathPattern), taken: bodies.keys, folder: bodyFolder)
                    bodies[file] = Data(body.utf8)
                    respond["bodyFile"] = file
                } else {
                    respond["body"] = body
                }
                object["respond"] = respond
            case .patch(let patch):
                object["patch"] = [
                    "delay": patch.delay,
                    "operations": patch.operations.map(operation)
                ]
            }
            return object
        }
        let root: [String: Any] = ["version": 1, "id": set.id.uuidString, "name": set.name, "rules": rules]
        do {
            let json = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            return Encoded(json: json, bodies: bodies)
        } catch {
            throw MockSetError.writeFailed(error.localizedDescription)
        }
    }

    static func decode(_ data: Data, file: String, readBody: (String) -> Data?) throws -> MockSet {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw MockSetError.unreadable(file: file, reason: "It is not a JSON object.")
        }
        guard let id = (root["id"] as? String).flatMap(UUID.init(uuidString:)) else {
            throw MockSetError.unreadable(file: file, reason: "The \"id\" field is missing or is not a UUID.")
        }
        let rules = try (root["rules"] as? [[String: Any]] ?? []).enumerated().map { index, object in
            try rule(from: object, file: file, index: index, readBody: readBody)
        }
        return MockSet(id: id, name: root["name"] as? String ?? file, rules: rules)
    }

    private static func rule(from object: [String: Any], file: String, index: Int, readBody: (String) -> Data?) throws -> MockRule {
        guard let path = object["path"] as? String else {
            throw MockSetError.unreadable(file: file, reason: "Rule \(index + 1) has no \"path\".")
        }
        let action: MockAction
        if let respond = object["respond"] as? [String: Any] {
            let body = (respond["bodyFile"] as? String).flatMap(readBody).map { String(decoding: $0, as: UTF8.self) } ?? respond["body"] as? String ?? ""
            action = .respond(MockResponse(
                status: respond["status"] as? Int ?? 200,
                headers: (respond["headers"] as? [String: String] ?? [:]).map { HTTPHeader(name: $0.key, value: $0.value) }.sorted { $0.name < $1.name },
                body: body,
                delay: respond["delay"] as? Double ?? 0
            ))
        } else if let patch = object["patch"] as? [String: Any] {
            let operations = (patch["operations"] as? [[String: Any]] ?? []).compactMap(operation(from:))
            action = .patch(MockPatch(operations: operations, delay: patch["delay"] as? Double ?? 0))
        } else {
            throw MockSetError.unreadable(file: file, reason: "Rule \(index + 1) has neither \"respond\" nor \"patch\".")
        }
        return MockRule(
            id: (object["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID(),
            isEnabled: object["enabled"] as? Bool ?? true,
            method: (object["method"] as? String).flatMap { $0.isEmpty ? nil : $0.uppercased() },
            pathPattern: path,
            query: (object["query"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            action: action
        )
    }

    private static func headers(_ headers: [HTTPHeader]) -> [String: String] {
        Dictionary(NetworkRequestRedactor.headers(headers).map { ($0.name, $0.value) }) { _, last in last }
    }

    private static func operation(_ operation: JSONPatchOperation) -> [String: Any] {
        guard let value = operation.value else {
            return ["path": operation.keyPath, "remove": true]
        }
        let redacted = LogRedactor.redact(value)
        return ["path": operation.keyPath, "value": JSONPatcher.parsedValue(redacted)]
    }

    private static func operation(from object: [String: Any]) -> JSONPatchOperation? {
        guard let path = object["path"] as? String else { return nil }
        if object["remove"] as? Bool == true {
            return JSONPatchOperation(keyPath: path, value: nil)
        }
        guard let value = object["value"] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys, .withoutEscapingSlashes]) else { return nil }
        return JSONPatchOperation(keyPath: path, value: String(decoding: data, as: UTF8.self))
    }

    private static func uniqueName(_ name: String, taken: Dictionary<String, Data>.Keys, folder: String) -> String {
        let base = (name as NSString).deletingPathExtension
        var candidate = "\(folder)/\(name)"
        var counter = 2
        while taken.contains(candidate) {
            candidate = "\(folder)/\(base)_\(counter).json"
            counter += 1
        }
        return candidate
    }
}
