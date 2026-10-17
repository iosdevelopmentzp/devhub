import Testing
@testable import DevHubDomain

@Suite struct MockLaunchEnvironmentTests {

    @Test func portBecomesTheStubBaseURL() {
        #expect(MockLaunchEnvironment.variables(port: 52001) == ["DEVHUB_BASE_URL": "http://127.0.0.1:52001"])
    }

    @Test func noPortMeansNoVariables() {
        #expect(MockLaunchEnvironment.variables(port: nil).isEmpty)
    }
}
