import Foundation

package enum CustomTabPolicy {
    package static let minimumInterval = 5

    package static func refresh(for source: TabSource) -> TabRefresh {
        guard let value = source.refresh?.trimmed.lowercased(), value.isEmpty == false, value != "onopen" else { return .onOpen }
        if value == "manual" {
            return .manual
        }
        guard let seconds = Int(value), seconds > 0 else { return .onOpen }
        return .every(seconds: max(seconds, minimumInterval))
    }

    package static func sourceActionID(for source: TabSource) -> String {
        "script:\(ScriptHeaderParser.fileBaseName(source.script))"
    }
}
