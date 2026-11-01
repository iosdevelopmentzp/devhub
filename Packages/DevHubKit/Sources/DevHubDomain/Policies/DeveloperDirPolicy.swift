import Foundation

package enum DeveloperDirPolicy {
    package static let contents = "/Contents/Developer"
    package static let tools: Set<String> = ["xcodebuild", "xcrun", "xed"]

    package static func developerDir(of path: String) -> String {
        let trimmed = ProjectPath(path.trimmed).expanded.trimmingSuffix("/")
        guard trimmed.hasSuffix(".app") else { return trimmed }
        return trimmed + contents
    }

    package static func appPath(ofDeveloperDir path: String) -> String {
        let trimmed = path.trimmingSuffix("/")
        guard trimmed.hasSuffix(contents) else { return trimmed }
        return String(trimmed.dropLast(contents.count))
    }

    package static func effective(choice: String?, config: String?) -> String? {
        let picked = [choice, config].compactMap { $0?.trimmed }.first { $0.isEmpty == false }
        return picked.map(developerDir)
    }

    package static func applies(to executable: String) -> Bool {
        tools.contains(executable)
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        var value = self
        while value.count > 1, value.hasSuffix(suffix) {
            value.removeLast(suffix.count)
        }
        return value
    }
}
