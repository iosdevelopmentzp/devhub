import Testing
@testable import DevHubDomain

@Suite struct MockSetLocationPolicyTests {
    private let projectPath = "/Users/alex/Projects/example-app"

    @Test func withoutAFolderTheProjectFolderNameIsTheKey() {
        #expect(MockSetLocationPolicy.location(network: nil, projectPath: projectPath) == .defaultFolder(project: "example-app"))
        #expect(MockSetLocationPolicy.location(network: NetworkConfig(mocksFolder: " "), projectPath: projectPath) == .defaultFolder(project: "example-app"))
    }

    @Test func aRelativeFolderIsInsideTheProject() {
        #expect(MockSetLocationPolicy.location(network: NetworkConfig(mocksFolder: "Tests/Mocks"), projectPath: projectPath) == .folder("/Users/alex/Projects/example-app/Tests/Mocks"))
        #expect(MockSetLocationPolicy.location(network: NetworkConfig(mocksFolder: "../shared"), projectPath: projectPath) == .folder("/Users/alex/Projects/shared"))
    }

    @Test func anAbsoluteOrHomeFolderStays() {
        #expect(MockSetLocationPolicy.location(network: NetworkConfig(mocksFolder: "/tmp/mocks"), projectPath: projectPath) == .folder("/tmp/mocks"))
        #expect(MockSetLocationPolicy.location(network: NetworkConfig(mocksFolder: "~/mocks"), projectPath: projectPath) == .folder(ProjectPath("~/mocks").expanded))
    }
}
