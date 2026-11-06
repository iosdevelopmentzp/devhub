import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ConfigDecodingTests {
    @Test func decodesAProjectFile() throws {
        let config = try ConfigDecoding.decode(ProjectConfig.self, from: ConfigDecoding.parseJSON(ConfigFixture.projectJSON))

        #expect(config.name == "Example App")
        #expect(config.kind == .xcode)
        #expect(config.xcode?.schemes == ["ExampleApp", "ExampleWidget"])
        #expect(config.launch?.profiles?.first?.defaults?.first?.value == "3")
        #expect(config.home?.quickActions == ["builtin.buildRun", "clean"])
    }

    @Test func decodesTheLaunchIdentityProfileFieldsAndNetwork() throws {
        let json = """
        {
          "launch": {
            "identity": { "variable": "APP_DEVICE_ID", "keptVariable": "APP_KEEP_DEVICE_ID", "args": ["-skipOnboarding"], "cleanInstallOnChange": false },
            "profiles": [
              { "id": "staging", "title": "Staging", "storage": { "suite": "group.com.example.app", "key": "environment" }, "upstream": "https://api.staging.example.com", "tint": "purple" },
              { "id": "production", "title": "Production", "production": true }
            ]
          },
          "network": { "baseURLVariable": "APP_BASE_URL", "mocksFolder": "~/mocks/example" }
        }
        """

        let config = try ConfigDecoding.decode(ProjectConfig.self, from: ConfigDecoding.parseJSON(json))

        #expect(config.launch?.identity == LaunchIdentityConfig(variable: "APP_DEVICE_ID", keptVariable: "APP_KEEP_DEVICE_ID", args: ["-skipOnboarding"], cleanInstallOnChange: false))
        #expect(config.launch?.profiles?.first?.storage == ProfileStorage(suite: "group.com.example.app", key: "environment"))
        #expect(config.launch?.profiles?.first?.upstream == "https://api.staging.example.com")
        #expect(config.launch?.profiles?.first?.isProduction == false)
        #expect(config.launch?.profiles?.last?.isProduction == true)
        #expect(config.launch?.profiles?.first?.tint == .purple)
        #expect(config.launch?.profiles?.last?.tint == nil)
        #expect(config.network == NetworkConfig(baseURLVariable: "APP_BASE_URL", mocksFolder: "~/mocks/example"))
    }

    @Test func anIdentityWithoutAVariableIsAnIssue() {
        #expect(throws: ConfigError.self) {
            try ConfigDecoding.decode(LaunchIdentityConfig.self, from: ["args": ["-x"]])
        }
    }

    @Test func aWrongRunTypeNamesThePath() {
        let object: [String: Any] = ["id": "x", "title": "X", "run": ["script": 3]]

        #expect(throws: ConfigError.self) {
            try ConfigDecoding.decode(ActionConfig.self, from: object)
        }
        #expect(describe(object).contains("run"))
    }

    @Test func aMissingKeyIsNamed() {
        #expect(describe(["title": "X", "run": ["open": "x"]]) == "id: this key is required.")
    }

    @Test func flexibleDefaultsTakeNumbersAndBooleans() throws {
        let input = try ConfigDecoding.decode(ActionInput.self, from: ["key": "n", "type": "toggle", "default": true])
        let number = try ConfigDecoding.decode(ActionInput.self, from: ["key": "n", "type": "number", "default": 4])

        #expect(input.defaultValue == "true")
        #expect(input.title == "n")
        #expect(number.defaultValue == "4")
    }

    @Test func invalidJSONIsAnIssueNotACrash() {
        #expect(throws: ConfigError.self) {
            try ConfigDecoding.parseJSON("{ nope")
        }
    }

    @Test func deepMergeKeepsNestedKeysAndTheTopWins() {
        let merged = ConfigDecoding.deepMerge(
            ["git": ["baseBranch": "origin/main", "commitPrefix": ["format": "$1: "]], "name": "A"],
            ["git": ["baseBranch": "origin/develop"], "name": "B"]
        )

        #expect(merged["name"] as? String == "B")
        let git = merged["git"] as? [String: Any]
        #expect(git?["baseBranch"] as? String == "origin/develop")
        #expect(git?["commitPrefix"] != nil)
    }

    private func describe(_ object: [String: Any]) -> String {
        do {
            _ = try ConfigDecoding.decode(ActionConfig.self, from: object)
            return ""
        } catch {
            return error.localizedDescription
        }
    }
}
