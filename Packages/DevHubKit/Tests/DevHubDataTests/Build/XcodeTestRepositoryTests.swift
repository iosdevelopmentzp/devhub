import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct XcodeTestRepositoryTests {
    @Test func argumentsPinTheSchemeDestinationAndResultBundle() {
        let request = TestRunRequest(projectPath: "/repo", container: nil, scheme: "App", configuration: "Debug", simulatorUDID: "SIM-1", simulatorName: "iPhone 17")

        let arguments = XcodeTestRepository.arguments(container: ["-workspace", "/repo/App.xcworkspace"], request: request, resultBundlePath: "/tmp/DevHub-tests/App-1.xcresult")

        #expect(arguments == [
            "-workspace", "/repo/App.xcworkspace",
            "-scheme", "App",
            "-configuration", "Debug",
            "-destination", "id=SIM-1",
            "-resultBundlePath", "/tmp/DevHub-tests/App-1.xcresult",
            "test",
        ])
    }
}
