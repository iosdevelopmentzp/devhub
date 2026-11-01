import Foundation
import DevHubDomain

enum AppGroupListParser {
    static func groups(from text: String) -> [AppDataFile] {
        text
            .split(whereSeparator: \.isNewline)
            .compactMap { group(String($0)) }
            .sorted { $0.name < $1.name }
    }

    private static func group(_ line: String) -> AppDataFile? {
        let separator = line.firstIndex(of: "\t") ?? line.firstIndex(of: " ")
        guard let separator else { return nil }
        let name = line[..<separator].trimmingCharacters(in: .whitespaces)
        let path = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        guard name.isEmpty == false, path.hasPrefix("/") else { return nil }
        return AppDataFile(name: name, path: path, size: 0)
    }
}
