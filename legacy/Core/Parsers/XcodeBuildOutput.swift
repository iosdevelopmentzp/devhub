import Foundation

nonisolated enum XcodeBuildOutput {
    private static let verbs: [String: String] = [
        "SwiftCompile": "Compiling", "CompileSwift": "Compiling", "CompileSwiftSources": "Compiling",
        "SwiftDriver": "Compiling", "SwiftEmitModule": "Compiling", "CompileC": "Compiling",
        "ProcessPCH": "Compiling", "CompileXIB": "Compiling", "CompileStoryboard": "Compiling",
        "CompileMetalFile": "Compiling", "CompileAssetCatalog": "Compiling assets",
        "Ld": "Linking", "Libtool": "Linking", "LinkStoryboards": "Linking",
        "PhaseScriptExecution": "Running script", "CodeSign": "Signing",
        "CopySwiftLibs": "Copying", "CpResource": "Copying", "Copy": "Copying", "PBXCp": "Copying",
        "ProcessInfoPlistFile": "Processing Info.plist", "GenerateDSYMFile": "Generating dSYM",
        "Touch": "Finishing", "Validate": "Finishing", "RegisterExecutionPolicyException": "Finishing"
    ]
    private static let productVerbs: Set<String> = ["Touch", "Validate", "CodeSign", "RegisterExecutionPolicyException"]

    static func step(for line: String) -> String? {
        if line.hasPrefix("Resolve Package Graph") || line.hasPrefix("Resolved source packages") {
            return "Resolving packages"
        }
        guard let verb = line.split(separator: " ", maxSplits: 1).first, let word = verbs[String(verb)] else { return nil }
        guard let target = target(in: line) else { return word }
        return "\(word) · \(target)"
    }

    static func errorMessage(in line: String) -> String? {
        guard let range = line.range(of: "error: ") else { return nil }
        let text = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        guard text.isEmpty == false else { return nil }
        let prefix = String(line[..<range.lowerBound]).trimmingCharacters(in: CharacterSet(charactersIn: ": "))
        guard line.hasPrefix("/"), prefix.isEmpty == false else { return text }
        let name = (prefix as NSString).lastPathComponent
        return "\(name): \(text)"
    }

    static func appPath(in line: String, configuration: String) -> String? {
        guard let space = line.firstIndex(of: " ") else { return nil }
        guard productVerbs.contains(String(line[..<space])) else { return nil }
        var rest = String(line[line.index(after: space)...])
        if let marker = rest.range(of: " (in target ") {
            rest = String(rest[..<marker.lowerBound])
        }
        let path = rest.replacingOccurrences(of: "\\ ", with: " ").trimmingCharacters(in: .whitespaces)
        let folder = "/\(configuration)-iphonesimulator/"
        guard let found = path.range(of: folder) else { return nil }
        let tail = path[found.upperBound...]
        guard tail.hasSuffix(".app"), tail.contains("/") == false else { return nil }
        return path
    }

    private static func target(in line: String) -> String? {
        guard let start = line.range(of: "(in target '") else { return nil }
        let rest = line[start.upperBound...]
        guard let end = rest.firstIndex(of: "'") else { return nil }
        return String(rest[..<end])
    }
}
