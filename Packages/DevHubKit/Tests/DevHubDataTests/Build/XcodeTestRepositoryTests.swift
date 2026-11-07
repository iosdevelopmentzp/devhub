import DevHubDomain
import DevHubTestSupport
import Foundation
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

    @Test func onlyTestsAddOneFilterEach() {
        let request = TestRunRequest(projectPath: "/repo", container: nil, scheme: "App", configuration: "Debug", simulatorUDID: "SIM-1", simulatorName: "iPhone 17", onlyTests: ["AppTests/LoginTests/testLogout", "AppTests/FeedTests/testFeed"])

        let arguments = XcodeTestRepository.arguments(container: [], request: request, resultBundlePath: "/tmp/b.xcresult")

        #expect(arguments.suffix(3) == ["-only-testing:AppTests/LoginTests/testLogout", "-only-testing:AppTests/FeedTests/testFeed", "test"])
    }

    @Test func theBundleIsReadWithXcresulttool() {
        #expect(XcodeTestRepository.resultsArguments(bundlePath: "/tmp/b.xcresult") == ["xcresulttool", "get", "test-results", "tests", "--path", "/tmp/b.xcresult"])
        #expect(XcodeTestRepository.exportArguments(bundlePath: "/tmp/b.xcresult", folder: "/tmp/out") == ["xcresulttool", "export", "attachments", "--path", "/tmp/b.xcresult", "--output-path", "/tmp/out"])
    }

    @Test func attachmentsLiveNextToTheBundles() {
        let repository = XcodeTestRepository(shell: ShellRunner(recorder: SpyCommandRecorder()), resultsFolder: URL(fileURLWithPath: "/tmp/DevHub-tests"))

        #expect(repository.attachmentsFolder(forBundle: "/tmp/DevHub-tests/App-1.xcresult").path == "/tmp/DevHub-tests/Attachments/App-1")
    }
}
