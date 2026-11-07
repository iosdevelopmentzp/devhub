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

    @Test func decodesThePullRequestFileGroups() throws {
        let json = """
        {
          "git": {
            "pullRequests": {
              "fileGroups": [
                { "name": "Tests", "patterns": ["*Tests/*", "*Tests.swift"], "hidden": true },
                { "name": "App", "patterns": ["*/App/*"] }
              ]
            }
          }
        }
        """

        let config = try ConfigDecoding.decode(ProjectConfig.self, from: ConfigDecoding.parseJSON(json))

        #expect(config.git?.pullRequests?.fileGroups == [
            FileGroupConfig(name: "Tests", patterns: ["*Tests/*", "*Tests.swift"], hidden: true),
            FileGroupConfig(name: "App", patterns: ["*/App/*"], hidden: nil),
        ])
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

    @Test func aCopyRunTakesAnOptionalOpenTarget() throws {
        let withOpen = try ConfigDecoding.decode(ActionConfig.self, from: ["id": "x", "title": "X", "run": ["copy": "{env} coins {user}", "open": "example://chat"]])
        let plain = try ConfigDecoding.decode(ActionConfig.self, from: ["id": "x", "title": "X", "run": ["copy": "hello"]])
        let open = try ConfigDecoding.decode(ActionConfig.self, from: ["id": "x", "title": "X", "run": ["open": "example://chat"]])

        #expect(withOpen.run == .copy("{env} coins {user}", open: "example://chat"))
        #expect(plain.run == .copy("hello", open: nil))
        #expect(open.run == .open("example://chat"))
        #expect(withOpen.run.copyTemplate == "{env} coins {user}")
        #expect(open.run.copyTemplate == nil)
    }

    @Test func aRunWithoutAKnownShapeNamesTheShapes() {
        #expect(describe(["id": "x", "title": "X", "run": ["shell": "ls"]]).contains("script, command, terminal, open or copy"))
    }

    @Test func aCopyRunRoundTripsThroughCodable() throws {
        let run = ActionRun.copy("hello", open: "example://chat")

        let data = try JSONEncoder().encode(run)

        #expect(try JSONDecoder().decode(ActionRun.self, from: data) == run)
    }

    @Test func aTabDecodesSharedInputsWithRecentAndOptionConfirmations() throws {
        let json = """
        {
          "id": "chat",
          "title": "Chat",
          "inputs": [
            { "key": "env", "title": "Environment", "type": "choice", "options": [{ "value": "/qabot", "title": "QA" }, { "value": "/prodbot", "title": "PROD", "confirm": "Send to PROD?" }], "default": "/qabot" },
            { "key": "user", "title": "User ID", "type": "text", "recent": true }
          ],
          "sections": [{ "title": "Accounts", "actions": ["chat-coins"] }]
        }
        """

        let tab = try ConfigDecoding.decode(TabConfig.self, from: ConfigDecoding.parseJSON(json))

        #expect(tab.inputs?.map(\.key) == ["env", "user"])
        #expect(tab.inputs?.first?.options?.last == InputOption(value: "/prodbot", title: "PROD", confirm: "Send to PROD?"))
        #expect(tab.inputs?.first?.options?.first?.confirm == nil)
        #expect(tab.inputs?.last?.recent == true)
        #expect(tab.inputs?.first?.recent == nil)
        #expect(tab.actionIDs == ["chat-coins"])
    }

    @Test func aTabDecodesItsPlacement() throws {
        let bar = try ConfigDecoding.decode(TabConfig.self, from: ConfigDecoding.parseJSON(#"{ "id": "qa", "title": "QA", "placement": "bar" }"#))
        let plain = try ConfigDecoding.decode(TabConfig.self, from: ConfigDecoding.parseJSON(#"{ "id": "qa", "title": "QA" }"#))

        #expect(bar.placement == .bar)
        #expect(plain.placement == nil)
        #expect(throws: ConfigError.self) {
            try ConfigDecoding.decode(TabConfig.self, from: ConfigDecoding.parseJSON(#"{ "id": "qa", "title": "QA", "placement": "sidebar" }"#))
        }
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

    @Test func decodesTheTrackerSection() throws {
        let json = """
        { "tracker": { "kind": "jira", "project": "ABC", "statuses": ["To Do", "In Progress", "Done"], "startStatus": "In Progress", "filter": "type != Epic", "branchFormat": "fix/{key}" } }
        """

        let config = try ConfigDecoding.decode(ProjectConfig.self, from: ConfigDecoding.parseJSON(json))

        #expect(config.tracker == TrackerConfig(kind: .jira, project: "ABC", statuses: ["To Do", "In Progress", "Done"], startStatus: "In Progress", filter: "type != Epic", branchFormat: "fix/{key}"))
    }

    @Test func theTrackerCanBeTurnedOffWithNone() throws {
        let json = """
        { "tracker": { "kind": "none" } }
        """

        let config = try ConfigDecoding.decode(ProjectConfig.self, from: ConfigDecoding.parseJSON(json))

        #expect(config.tracker?.kind == .disabled)
    }

    @Test func anUnknownTrackerKindIsAnError() {
        let json = """
        { "tracker": { "kind": "linear" } }
        """

        #expect(throws: ConfigError.self) {
            try ConfigDecoding.decode(ProjectConfig.self, from: ConfigDecoding.parseJSON(json))
        }
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
