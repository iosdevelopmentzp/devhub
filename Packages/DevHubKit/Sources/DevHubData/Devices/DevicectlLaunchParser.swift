import Foundation

enum DevicectlLaunchParser {
    private struct Output: Decodable {
        let result: Result?
    }

    private struct Result: Decodable {
        let process: Process?
    }

    private struct Process: Decodable {
        let processIdentifier: Int32?
    }

    static func pid(from data: Data) -> Int32? {
        (try? JSONDecoder().decode(Output.self, from: data))?.result?.process?.processIdentifier
    }
}
