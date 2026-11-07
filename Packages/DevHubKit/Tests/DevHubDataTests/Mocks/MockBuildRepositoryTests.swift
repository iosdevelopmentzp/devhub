import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockBuildRepositoryTests {
    private let repository = MockBuildRepository()

    @Test func answersSchemesAndProduct() async throws {
        let request = BuildRequest(
            projectPath: "~/App",
            container: nil,
            scheme: "App",
            configuration: "Debug",
            incremental: true,
            simulatorUDID: "sim",
            simulatorName: "iPhone 17",
            cleanInstall: false, launch: .none,
            attachDebugger: false
        )

        #expect(await repository.schemes(projectPath: "~/App", container: nil).first == "ExampleApp")
        #expect(repository.lastBuiltAppPath(projectPath: "~/App", container: nil, scheme: "App", configuration: "Debug", isPhysicalDevice: false) == nil)
        let product = try await repository.locateProduct(request, hints: [])
        #expect(product.appPath.hasSuffix("Debug-iphonesimulator/App.app"))
        #expect(product.bundleID == "com.example.app")
    }
}
