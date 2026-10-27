import Foundation
import DevHubDomain

enum BuildOutputParser {
    private static let verbs: [String: String] = [
        "SwiftCompile": "Compiling",
        "CompileSwift": "Compiling",
        "CompileSwiftSources": "Compiling",
        "SwiftDriver": "Compiling",
        "SwiftEmitModule": "Compiling",
        "CompileC": "Compiling",
        "ProcessPCH": "Compiling",
        "CompileXIB": "Compiling",
        "CompileStoryboard": "Compiling",
        "CompileAssetCatalog": "Compiling assets",
        "CompileMetalFile": "Compiling",
        "Ld": "Linking",
        "Libtool": "Linking",
        "LinkStoryboards": "Linking",
        "PhaseScriptExecution": "Running script",
        "CodeSign": "Signing",
        "CopySwiftLibs": "Copying",
        "CpResource": "Copying",
        "Copy": "Copying",
        "PBXCp": "Copying",
        "ProcessInfoPlistFile": "Processing Info.plist",
        "GenerateDSYMFile": "Generating dSYM",
        "Touch": "Finishing",
        "Validate": "Finishing",
        "RegisterExecutionPolicyException": "Finishing"
    ]

    static func step(from line: String) -> String? {
        guard let first = line.first, first.isWhitespace == false else { return nil }
        if line.hasPrefix("Resolve Package Graph") || line.hasPrefix("Resolved source packages") {
            return "Resolving packages"
        }
        guard let token = line.split(separator: " ", maxSplits: 1).first, let verb = verbs[String(token)] else { return nil }
        guard let target = target(in: line) else { return verb }
        return "\(verb) · \(target)"
    }

    static func error(from line: String) -> String? {
        guard line.contains("error: ") else { return nil }
        let trimmed = line.trimmed
        guard trimmed.hasPrefix("/") else { return trimmed }
        return (trimmed as NSString).lastPathComponent
    }

    private static let locatedIssue = try? NSRegularExpression(pattern: #"^(/[^:]+):(\d+):(?:(\d+):)? (error|warning): (.+)$"#)

    static func issue(from line: String) -> BuildIssue? {
        let trimmed = line.trimmed
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        if let match = locatedIssue?.firstMatch(in: trimmed, range: range) {
            func group(_ index: Int) -> String? {
                Range(match.range(at: index), in: trimmed).map { String(trimmed[$0]) }
            }
            return BuildIssue(
                severity: group(4) == "warning" ? .warning : .error,
                path: group(1),
                line: group(2).flatMap { Int($0) },
                column: group(3).flatMap { Int($0) },
                message: group(5) ?? ""
            )
        }
        guard trimmed.hasPrefix("error: ") || trimmed.hasPrefix("xcodebuild: error: ") else { return nil }
        let message = trimmed.components(separatedBy: "error: ").dropFirst().joined(separator: "error: ")
        return BuildIssue(severity: .error, path: nil, line: nil, column: nil, message: message)
    }

    static func appPath(from line: String) -> String? {
        let parts = line.split(separator: " ", maxSplits: 1)
        guard parts.count == 2, appPathActions.contains(String(parts[0])) else { return nil }
        var rest = String(parts[1])
        if let range = rest.range(of: " (in target '") {
            rest = String(rest[..<range.lowerBound])
        }
        let path = rest.replacingOccurrences(of: "\\ ", with: " ").trimmed
        guard path.hasPrefix("/"), path.hasSuffix(".app") else { return nil }
        return path
    }

    private static let appPathActions: Set<String> = ["Touch", "Validate", "RegisterExecutionPolicyException", "CodeSign"]

    private static func target(in line: String) -> String? {
        guard let range = line.range(of: "(in target '") else { return nil }
        let rest = line[range.upperBound...]
        guard let end = rest.firstIndex(of: "'") else { return nil }
        return String(rest[..<end])
    }
}
