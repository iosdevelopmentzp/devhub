import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockAppLogRepositoryTests {
    private let repository = MockAppLogRepository()

    @Test func answersExecutableName() async {
        #expect(await repository.executableName(udid: "sim", bundleID: "com.example.app") == "ExampleApp")
    }

    @Test func streamYieldsLinesRightAway() async throws {
        var iterator = repository.stream(udid: "sim", process: "ExampleApp").makeAsyncIterator()

        let first = try #require(try await iterator.next())

        #expect(first.id == 0)
        #expect(first.level == .info)
    }
}
