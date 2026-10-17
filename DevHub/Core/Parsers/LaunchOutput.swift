import Foundation

nonisolated enum LaunchOutput {
    static func processID(in output: String) -> Int? {
        for line in output.split(whereSeparator: \.isNewline).reversed() {
            guard let colon = line.lastIndex(of: ":") else { continue }
            let tail = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if let value = Int(tail) {
                return value
            }
        }
        return nil
    }
}
