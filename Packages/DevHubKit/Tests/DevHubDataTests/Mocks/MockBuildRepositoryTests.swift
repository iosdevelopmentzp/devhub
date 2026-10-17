import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockBuildRepositoryTests {
    private let repository = MockBuildRepository()

    @Test func answersSchemesAndProduct() async throws {
        let request = BuildRequest(
            projectPath: "~/App",
            scheme: "App",
            configuration: "Debug",
            incremental: true,
            simulatorUDID: "sim",
            simulatorName: "iPhone 17",
            identity: nil,
            cleanInstall: false,
            attachDebugger: false
        )

        #expect(await repository.schemes(projectPath: "~/App").first == "ExampleApp")
        #expect(repository.lastBuiltAppPath(projectPath: "~/App", scheme: "App", configuration: "Debug") == nil)
        let product = try await repository.locateProduct(request, hints: [])
        #expect(product.appPath.hasSuffix("Debug-iphonesimulator/App.app"))
        #expect(product.bundleID == "com.example.app")
    }
}
