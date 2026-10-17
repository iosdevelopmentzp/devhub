import Foundation
import DevHubDomain

enum MockRouteName {

    static func fileName(method: String?, path: String) -> String {
        let verb = method.flatMap { $0.isEmpty ? nil : $0.uppercased() } ?? "ANY"
        let segments = path
            .split(separator: "/")
            .map { segment in String(segment.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" }) }
        return ([verb] + segments).joined(separator: "_") + ".json"
    }

    static func stem(for name: String) -> String {
        let cleaned = name.trimmed.map { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" ? $0 : "-" }
        let stem = String(cleaned).split(separator: "-", omittingEmptySubsequences: true).joined(separator: "-")
        return stem.isEmpty ? "set" : stem
    }
}
