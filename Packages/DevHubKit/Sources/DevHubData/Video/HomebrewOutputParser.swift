import Foundation
import DevHubDomain

enum HomebrewOutputParser {
    static func step(from line: String) -> String? {
        guard line.hasPrefix("==> ") else { return nil }
        let step = String(line.dropFirst(4)).trimmed
        return step.isEmpty ? nil : step
    }

    static func failure(from lines: [String], exitCode: Int32) -> String {
        let trimmed = lines.map(\.trimmed).filter { $0.isEmpty == false }
        if let error = trimmed.last(where: { $0.hasPrefix("Error:") }) {
            return String(error.dropFirst("Error:".count)).trimmed
        }
        return trimmed.last ?? "brew stopped with exit code \(exitCode)."
    }
}
