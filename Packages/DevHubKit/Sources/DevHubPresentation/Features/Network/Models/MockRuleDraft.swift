import Foundation
import DevHubDomain

struct MockRuleDraft: Equatable {
    enum Kind: String, CaseIterable, Identifiable {
        case respond
        case patch

        var id: String { rawValue }

        var title: String {
            switch self {
            case .respond: "Respond"
            case .patch: "Patch real response"
            }
        }
    }

    static let anyMethod = "ANY"
    static let methods = [anyMethod, "GET", "POST", "PUT", "PATCH", "DELETE"]

    var method: String
    var path: String
    var query: String
    var operationName: String
    var kind: Kind
    var status: String
    var contentType: String
    var body: String
    var patchLines: String
    var delayMilliseconds: String

    init(rule: MockRule) {
        method = rule.method?.uppercased() ?? Self.anyMethod
        path = rule.pathPattern
        query = rule.query ?? ""
        operationName = rule.operationName ?? ""
        delayMilliseconds = rule.action.delay > 0 ? String(Int((rule.action.delay * 1000).rounded())) : ""
        switch rule.action {
        case .respond(let response):
            kind = .respond
            status = String(response.status)
            contentType = response.headers.first { $0.name.caseInsensitiveCompare("Content-Type") == .orderedSame }?.value ?? ""
            body = response.body
            patchLines = ""
        case .patch(let patch):
            kind = .patch
            status = "200"
            contentType = ""
            body = ""
            patchLines = patch.operations.map(Self.line(for:)).joined(separator: "\n")
        }
    }

    var validationError: String? {
        let trimmedPath = path.trimmed
        if trimmedPath.hasPrefix("/") == false {
            return "The path must start with /."
        }
        if kind == .respond, (Int(status.trimmed).map { (100...599).contains($0) } ?? false) == false {
            return "The status must be a number from 100 to 599."
        }
        if delayMilliseconds.trimmed.isEmpty == false, (Int(delayMilliseconds.trimmed).map { $0 >= 0 } ?? false) == false {
            return "The delay must be a whole number of milliseconds."
        }
        if kind == .respond, Self.hasTypographicQuotes(in: body) {
            return "The body has typographic quotes (“ ”) next to JSON punctuation. Use straight quotes (\")."
        }
        if kind == .respond, let problem = Self.jsonProblem(body: body, contentType: contentType) {
            return "The body is not valid JSON: \(problem)"
        }
        if kind == .patch, Self.hasTypographicQuotes(in: patchLines) {
            return "The patch has typographic quotes (“ ”) next to JSON punctuation. Use straight quotes (\")."
        }
        if kind == .patch, let bad = patchLines.components(separatedBy: "\n").map(\.trimmed).first(where: { $0.isEmpty == false && Self.operation(from: $0) == nil }) {
            return "Write each patch line as key.path = JSON value, or remove key.path. This line is not valid: \(bad)"
        }
        return nil
    }

    func rule(id: MockRule.ID, isEnabled: Bool) -> MockRule? {
        guard validationError == nil else { return nil }
        let delay = (Double(delayMilliseconds.trimmed) ?? 0) / 1000
        let action: MockAction
        switch kind {
        case .respond:
            let type = contentType.trimmed
            action = .respond(MockResponse(
                status: Int(status.trimmed) ?? 200,
                headers: type.isEmpty ? [] : [HTTPHeader(name: "Content-Type", value: type)],
                body: body,
                delay: delay
            ))
        case .patch:
            let operations = patchLines.split(separator: "\n").compactMap { Self.operation(from: String($0)) }
            action = .patch(MockPatch(operations: operations, delay: delay))
        }
        let trimmedMethod = method.trimmed.uppercased()
        let trimmedQuery = query.trimmed
        let trimmedOperation = operationName.trimmed
        return MockRule(
            id: id,
            isEnabled: isEnabled,
            method: trimmedMethod.isEmpty || trimmedMethod == Self.anyMethod ? nil : trimmedMethod,
            pathPattern: path.trimmed,
            query: trimmedQuery.isEmpty ? nil : trimmedQuery,
            action: action,
            operationName: trimmedOperation.isEmpty ? nil : trimmedOperation
        )
    }

    static func operation(from line: String) -> JSONPatchOperation? {
        let text = line.trimmed
        if text.hasPrefix("remove ") {
            let keyPath = String(text.dropFirst("remove ".count)).trimmed
            return keyPath.isEmpty ? nil : JSONPatchOperation(keyPath: keyPath, value: nil)
        }
        guard let equals = text.firstIndex(of: "=") else { return nil }
        let keyPath = text[..<equals].trimmingCharacters(in: .whitespaces)
        let value = text[text.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        guard keyPath.isEmpty == false, keyPath.contains(" ") == false, value.isEmpty == false else { return nil }
        return JSONPatchOperation(keyPath: keyPath, value: value)
    }

    static func jsonProblem(body: String, contentType: String) -> String? {
        let text = body.trimmed
        let looksLikeJSON = contentType.lowercased().contains("json") || text.hasPrefix("{") || text.hasPrefix("[")
        guard looksLikeJSON, text.isEmpty == false else { return nil }
        do {
            _ = try JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed])
            return nil
        } catch {
            return (error as NSError).userInfo[NSDebugDescriptionErrorKey] as? String ?? error.localizedDescription
        }
    }

    static func hasTypographicQuotes(in text: String) -> Bool {
        text.range(of: #"[“”]\s*[:,}\]]|[:,{\[=]\s*[“”]"#, options: .regularExpression) != nil
    }

    static func line(for operation: JSONPatchOperation) -> String {
        guard let value = operation.value else { return "remove \(operation.keyPath)" }
        return "\(operation.keyPath) = \(value)"
    }
}
