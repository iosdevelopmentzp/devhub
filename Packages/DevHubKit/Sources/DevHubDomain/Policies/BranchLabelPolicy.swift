import Foundation

package enum BranchLabelPolicy {

    package static func labels(from text: String) -> [String] {
        merged([], adding: text.split(separator: ",").map(String.init))
    }

    package static func merged(_ labels: [String], adding added: [String]) -> [String] {
        var result: [String] = []
        for label in (labels + added).map(clean) where label.isEmpty == false {
            guard result.contains(where: { $0.caseInsensitiveCompare(label) == .orderedSame }) == false else { continue }
            result.append(label)
        }
        return result
    }

    package static func known(in marks: some Sequence<BranchMark>) -> [String] {
        merged([], adding: marks.flatMap(\.labels))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func clean(_ label: String) -> String {
        label
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
