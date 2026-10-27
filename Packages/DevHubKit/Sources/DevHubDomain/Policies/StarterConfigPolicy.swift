import Foundation

package enum StarterConfigPolicy {
    package static func projectJSON(_ facts: StarterConfigFacts) -> String {
        var git: [String: Any] = ["remote": facts.remote]
        if let kind = facts.hostKind {
            git["host"] = ["kind": kind.rawValue]
        }
        if let base = facts.baseBranch, base.isEmpty == false {
            git["baseBranch"] = base
        }
        var root: [String: Any] = ["name": facts.name, "git": git]
        if facts.scheme.isEmpty {
            root["kind"] = "command"
        } else {
            var xcode: [String: Any] = ["scheme": facts.scheme]
            if facts.bundleID.isEmpty == false {
                xcode["bundleID"] = facts.bundleID
            }
            root["kind"] = "xcode"
            root["xcode"] = xcode
        }
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: options) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}
