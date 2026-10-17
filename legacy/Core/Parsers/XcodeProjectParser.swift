import Foundation

nonisolated enum XcodeProjectParser {
    private static let excludedWords = ["Tests", "Extension", "Widget", "Clip", "$"]

    static func bundleID(inPbxproj text: String) -> String? {
        var candidates: [String] = []
        var searchRange = text.startIndex..<text.endIndex
        while let found = text.range(of: "PRODUCT_BUNDLE_IDENTIFIER", range: searchRange) {
            let lineEnd = text[found.upperBound...].firstIndex(of: "\n") ?? text.endIndex
            searchRange = lineEnd..<text.endIndex
            guard let value = assignedValue(text[found.upperBound..<lineEnd]) else { continue }
            guard excludedWords.contains(where: { value.contains($0) }) == false else { continue }
            candidates.append(value)
        }
        return candidates.min { $0.count < $1.count }
    }

    static func configurationNames(inPbxproj text: String) -> [String] {
        guard let start = text.range(of: "Begin XCBuildConfiguration section"),
              let end = text.range(of: "End XCBuildConfiguration section", range: start.upperBound..<text.endIndex) else { return [] }
        var names: [String] = []
        for line in text[start.upperBound..<end.lowerBound].split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasSuffix("= {"), let open = trimmed.range(of: " /* "), let close = trimmed.range(of: " */ = {") else { continue }
            let identifier = trimmed[..<open.lowerBound]
            guard identifier.count >= 20, identifier.allSatisfy({ $0.isHexDigit }) else { continue }
            let name = String(trimmed[open.upperBound..<close.lowerBound])
            if names.contains(name) == false {
                names.append(name)
            }
        }
        return names
    }

    static func referencedProjects(inWorkspaceData text: String) -> [String] {
        var paths: [String] = []
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("location") else { continue }
            guard let quote = trimmed.firstIndex(of: "\"") else { continue }
            let value = trimmed[trimmed.index(after: quote)...].dropLast()
            guard let colon = value.firstIndex(of: ":") else { continue }
            let path = String(value[value.index(after: colon)...])
            if path.hasSuffix(".xcodeproj") {
                paths.append(path)
            }
        }
        return paths
    }

    private static func assignedValue(_ tail: Substring) -> String? {
        guard let equals = tail.firstIndex(of: "=") else { return nil }
        var value = tail[tail.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        if value.hasSuffix(";") {
            value.removeLast()
        }
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
        return value.isEmpty ? nil : value
    }
}
