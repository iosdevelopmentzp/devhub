import Foundation
import DevHubDomain

enum CircleCITestResultParser {
    private struct TestResult: Decodable {
        let classname: String?
        let name: String?
        let result: String?
        let runTime: Double?
        let message: String?
    }

    static func results(from data: Data) throws -> [CITestResult] {
        try CircleCIJSON.decodeLines(TestResult.self, from: data).compactMap(result)
    }

    private static func result(_ dto: TestResult) -> CITestResult? {
        guard let name = dto.name, name.isEmpty == false else { return nil }
        return CITestResult(
            className: dto.classname ?? "",
            name: name,
            result: dto.result ?? "",
            runTime: dto.runTime,
            message: dto.message.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}
