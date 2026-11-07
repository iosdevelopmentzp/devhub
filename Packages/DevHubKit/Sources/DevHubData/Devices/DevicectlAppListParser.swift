import Foundation

enum DevicectlAppListParser {
    private struct Output: Decodable {
        let result: Result?
    }

    private struct Result: Decodable {
        let apps: [App]?
    }

    private struct App: Decodable {
        let bundleIdentifier: String
        let version: String?
    }

    static func apps(from data: Data) -> [(bundleID: String, version: String?)] {
        let apps = (try? JSONDecoder().decode(Output.self, from: data))?.result?.apps ?? []
        return apps.map { ($0.bundleIdentifier, $0.version) }
    }
}
