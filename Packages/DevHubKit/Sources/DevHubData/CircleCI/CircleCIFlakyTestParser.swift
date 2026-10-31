import Foundation
import DevHubDomain

enum CircleCIFlakyTestParser {
    private struct Page: Decodable {
        enum CodingKeys: String, CodingKey {
            case tests = "flaky-tests"
        }

        let tests: [FlakyTest]?
    }

    private struct FlakyTest: Decodable {
        enum CodingKeys: String, CodingKey {
            case classname
            case name = "test-name"
            case jobName = "job-name"
            case workflowName = "workflow-name"
            case timesFlaked = "times-flaked"
        }

        let classname: String?
        let name: String?
        let jobName: String?
        let workflowName: String?
        let timesFlaked: Int?
    }

    static func tests(from data: Data) throws -> [CIFlakyTest] {
        let page: Page
        do {
            page = try JSONDecoder().decode(Page.self, from: data)
        } catch {
            throw CIError.command("Cannot read the flaky tests of circleci: \(error.localizedDescription)")
        }
        return (page.tests ?? []).compactMap(test)
    }

    private static func test(_ dto: FlakyTest) -> CIFlakyTest? {
        guard let name = dto.name, name.isEmpty == false else { return nil }
        return CIFlakyTest(
            className: dto.classname ?? "",
            name: name,
            jobName: dto.jobName,
            workflowName: dto.workflowName,
            timesFlaked: dto.timesFlaked ?? 0
        )
    }
}
