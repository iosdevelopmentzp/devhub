import Foundation
import DevHubDomain

enum CopilotEventScanner {
    struct Prompts: Equatable {
        var first: String?
        var last: String?
    }

    private static let marker = Data(#"{"type":"user.message""#.utf8)

    static func scan(_ data: Data) -> Prompts {
        let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true)
        let messages = lines.lazy.filter { $0.starts(with: marker) }
        return Prompts(
            first: messages.lazy.compactMap(content).first,
            last: messages.reversed().lazy.compactMap(content).first
        )
    }

    private static func content(_ line: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let data = object["data"] as? [String: Any],
              let text = data["content"] as? String else { return nil }
        let single = text.split(whereSeparator: \.isNewline).joined(separator: " ").trimmed
        return single.isEmpty ? nil : single
    }
}
