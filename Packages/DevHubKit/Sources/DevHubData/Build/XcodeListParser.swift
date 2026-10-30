import Foundation

enum XcodeListParser {
    private struct Output: Decodable {
        let project: Container?
        let workspace: Container?
    }

    private struct Container: Decodable {
        let schemes: [String]?
        let targets: [String]?
    }

    static func names(from output: String) -> [String] {
        guard let start = output.firstIndex(of: "{"),
              let decoded = try? JSONDecoder().decode(Output.self, from: Data(output[start...].utf8))
        else { return [] }
        let containers = [decoded.workspace, decoded.project].compactMap { $0 }
        var names: [String] = []
        for name in containers.flatMap({ ($0.schemes ?? []) + ($0.targets ?? []) }) where names.contains(name) == false {
            names.append(name)
        }
        return names
    }
}
