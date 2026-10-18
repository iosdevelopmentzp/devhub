import Testing
@testable import DevHubDomain

@Suite struct MockLaunchEnvironmentTests {

    @Test func portGoesIntoTheBaseURLVariable() {
        #expect(MockLaunchEnvironment.variables(port: 52001, variable: "APP_BASE_URL") == ["APP_BASE_URL": "http://127.0.0.1:52001"])
    }

    @Test func noPortMeansNoVariables() {
        #expect(MockLaunchEnvironment.variables(port: nil, variable: "APP_BASE_URL").isEmpty)
    }

    @Test func noVariableMeansNoVariables() {
        #expect(MockLaunchEnvironment.variables(port: 52001, variable: nil).isEmpty)
        #expect(MockLaunchEnvironment.variables(port: 52001, variable: " ").isEmpty)
    }
}
