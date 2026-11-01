import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ProjectTests {
    @Test func aProjectSavedWithoutAnXcodeChoiceDecodes() throws {
        let json = #"{"id":"p1","name":"Example App","path":"~/Projects/example-app","scheme":"ExampleApp","bundleID":"com.example.app"}"#

        let project = try JSONDecoder().decode(Project.self, from: Data(json.utf8))

        #expect(project.name == "Example App")
        #expect(project.developerDir == nil)
    }

    @Test func theXcodeChoiceIsSaved() throws {
        let project = Project(id: "p1", name: "Example App", path: "~/Projects/example-app", scheme: "ExampleApp", bundleID: "com.example.app", developerDir: "/Applications/Xcode-beta.app/Contents/Developer")

        let decoded = try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project))

        #expect(decoded == project)
    }
}
