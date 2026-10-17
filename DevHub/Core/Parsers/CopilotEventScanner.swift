import Foundation

nonisolated struct CopilotPrompts: Sendable {
    var first: String?
    var last: String?
}

nonisolated enum CopilotEventScanner {
    static func scan(_ data: Data) -> CopilotPrompts {
        var prompts = CopilotPrompts()
        LineScanner.forEachLine(in: data) { line in
            guard LineScanner.hasPrefix(line, "{\"type\":\"user.message\"") else { return true }
            prompts.first = content(of: line)
            return false
        }
        LineScanner.forEachLineReversed(in: data) { line in
            guard LineScanner.hasPrefix(line, "{\"type\":\"user.message\"") else { return true }
            prompts.last = content(of: line)
            return false
        }
        return prompts
    }

    private static func content(of line: UnsafeRawBufferPointer) -> String? {
        guard let object = LineScanner.object(line), let data = object["data"] as? [String: Any] else { return nil }
        return SessionText.nonEmpty(data["content"] as? String)
    }
}
