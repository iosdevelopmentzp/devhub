import Foundation
import Testing
@testable import DevHubDomain

@Suite struct StarterConfigPolicyTests {
    @Test func anXcodeProjectGetsItsSchemeBundleIDAndGitFacts() throws {
        let json = StarterConfigPolicy.projectJSON(StarterConfigFacts(name: "Example App", scheme: "ExampleApp", bundleID: "com.example.app", remote: "origin", hostKind: .github, baseBranch: "main"))

        #expect(json == """
        {
          "git" : {
            "baseBranch" : "main",
            "host" : {
              "kind" : "github"
            },
            "remote" : "origin"
          },
          "kind" : "xcode",
          "name" : "Example App",
          "xcode" : {
            "bundleID" : "com.example.app",
            "scheme" : "ExampleApp"
          }
        }
        """)
    }

    @Test func aProjectWithoutASchemeIsACommandProject() throws {
        let json = StarterConfigPolicy.projectJSON(StarterConfigFacts(name: "tools", scheme: "", bundleID: "", remote: "origin", hostKind: nil, baseBranch: nil))
        let object = try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])

        #expect(object["kind"] as? String == "command")
        #expect(object["xcode"] == nil)
        #expect((object["git"] as? [String: Any])?.keys.sorted() == ["remote"])
    }
}
