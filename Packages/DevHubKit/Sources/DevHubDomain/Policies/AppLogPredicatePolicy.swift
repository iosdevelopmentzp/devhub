import Foundation

package enum AppLogPredicatePolicy {
    package static func predicate(for filter: AppLogFilter) -> String? {
        let subsystem = filter.subsystem.trimmed
        if subsystem.isEmpty == false {
            return "subsystem == \"\(escaped(subsystem))\""
        }
        let process = filter.process.trimmed
        guard process.isEmpty == false else { return nil }
        return "process == \"\(escaped(process))\""
    }

    private static func escaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
