import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ActionContextPolicyTests {
    private let effective = EffectiveProject(name: "Example App", kind: .xcode, schemes: ["ExampleApp"], scheme: "ExampleApp", configuration: "Debug", baseBranch: "origin/main", bundleID: "com.example.app")

    private func inputs(item: ActionItemContext = .none) -> ActionContextInputs {
        ActionContextInputs(
            projectPath: "/repo",
            projectName: "repo",
            checkoutPath: "/repo-wt",
            branch: "main",
            effective: effective,
            simulatorUDID: "SIM",
            simulatorName: "iPhone",
            appPath: "/tmp/App.app",
            configDir: "/repo/.devhub",
            item: item,
            inputs: ["target-name": "app"],
            version: "1.0"
        )
    }

    @Test func fillsEveryVariable() {
        let context = ActionContextPolicy.make(inputs())

        #expect(context.environment["DEVHUB_PROJECT_NAME"] == "Example App")
        #expect(context.environment["DEVHUB_CHECKOUT_PATH"] == "/repo-wt")
        #expect(context.environment["DEVHUB_MAIN_PATH"] == "/repo")
        #expect(context.environment["DEVHUB_BUNDLE_ID"] == "com.example.app")
        #expect(context.environment["DEVHUB_INPUT_TARGET_NAME"] == "app")
        #expect(context.placeholders["target-name"] == "app")
        #expect(context.placeholders["branch"] == "main")
    }

    @Test func profileHostAndContainersBecomeVariables() {
        var values = inputs()
        values.profileID = "staging"
        values.hostKind = .gitlab
        values.containers = AppContainers(app: "/sim/Bundle/App.app", data: "/sim/Data/App")

        let environment = ActionContextPolicy.make(values).environment

        #expect(environment["DEVHUB_PROFILE"] == "staging")
        #expect(environment["DEVHUB_HOST"] == "gitlab")
        #expect(environment["DEVHUB_APP_CONTAINER"] == "/sim/Bundle/App.app")
        #expect(environment["DEVHUB_DATA_CONTAINER"] == "/sim/Data/App")
    }

    @Test func unknownProfileHostAndContainersAreEmptyStrings() {
        let environment = ActionContextPolicy.make(inputs()).environment

        #expect(["DEVHUB_PROFILE", "DEVHUB_HOST", "DEVHUB_APP_CONTAINER", "DEVHUB_DATA_CONTAINER", "DEVHUB_GROUP_CONTAINERS", "DEVHUB_SIMULATOR_STATE"].map { environment[$0] } == ["", "", "", "", "", ""])
    }

    @Test func groupContainersBecomeOneLinePerGroup() {
        var values = inputs()
        values.containers = AppContainers(app: "", data: "", groups: [
            AppDataFile(name: "group.com.example.app", path: "/sim/Shared/A", size: 0),
            AppDataFile(name: "group.com.example.app.widget", path: "/sim/Shared/B", size: 0)
        ])

        let environment = ActionContextPolicy.make(values).environment

        #expect(environment["DEVHUB_GROUP_CONTAINERS"] == "group.com.example.app\t/sim/Shared/A\ngroup.com.example.app.widget\t/sim/Shared/B")
    }

    @Test func simulatorStateBecomesText() {
        let states: [Simulator.State?] = [.booted, .shutdown, .booting, .shuttingDown, nil]

        let texts = states.map { state in
            var values = inputs()
            values.simulatorState = state
            return ActionContextPolicy.make(values).environment["DEVHUB_SIMULATOR_STATE"]
        }

        #expect(texts == ["booted", "shutdown", "booting", "shutting-down", ""])
    }

    @Test func theItemBundleIDWins() {
        let context = ActionContextPolicy.make(inputs(item: ActionItemContext(bundleID: "com.example.app.widget")))

        #expect(context.bundleID == "com.example.app.widget")
    }

    @Test func theRowItemWins() {
        let context = ActionContextPolicy.make(inputs(item: ActionItemContext(branch: "feature/ABC-1", worktreePath: "/wt", simulatorUDID: "ROW", simulatorName: "iPad", rowID: "r1")))

        #expect(context.branch == "feature/ABC-1")
        #expect(context.worktreePath == "/wt")
        #expect(context.simulatorUDID == "ROW")
        #expect(context.rowID == "r1")
    }

    @Test func defaultsResolveSpecialValues() {
        func value(_ type: InputType, _ defaultValue: String?, options: [InputOption]? = nil) -> String {
            ActionContextPolicy.defaultValue(for: ActionInput(key: "k", title: "K", type: type, options: options, defaultValue: defaultValue), branch: "main", simulatorUDID: "SIM", scheme: "ExampleApp")
        }

        #expect(value(.branch, "current") == "main")
        #expect(value(.simulator, "target") == "SIM")
        #expect(value(.toggle, nil) == "false")
        #expect(value(.scheme, nil) == "ExampleApp")
        #expect(value(.choice, nil, options: [InputOption(value: "a")]) == "a")
        #expect(value(.text, "x") == "x")
    }

    @Test func workingFolderNamesAndPaths() {
        let context = ActionContextPolicy.make(inputs())

        #expect(ActionContextPolicy.workingFolder(nil, context: context, home: "/Users/alex") == "/repo-wt")
        #expect(ActionContextPolicy.workingFolder("main", context: context, home: "/Users/alex") == "/repo")
        #expect(ActionContextPolicy.workingFolder("Tools/{branch}", context: context, home: "/Users/alex") == "/repo/Tools/main")
        #expect(ActionContextPolicy.workingFolder("~/tmp", context: context, home: "/Users/alex") == "/Users/alex/tmp")
    }

    @Test func aPullRequestRowFillsItsNumberAndLink() {
        let item = ActionItemContext(branch: "feature/ABC-1", rowID: "7", pullRequestNumber: 7, pullRequestURL: URL(string: "https://github.com/example/app/pull/7"))

        let context = ActionContextPolicy.make(inputs(item: item))

        #expect(context.environment["DEVHUB_PR_NUMBER"] == "7")
        #expect(context.environment["DEVHUB_PR_URL"] == "https://github.com/example/app/pull/7")
        #expect(context.environment["DEVHUB_BRANCH"] == "feature/ABC-1")
        #expect(ActionContextPolicy.make(inputs()).environment["DEVHUB_PR_NUMBER"] == "")
    }

    @Test func theSimulatorKindSaysSimulatorOrDevice() {
        var device = inputs()
        device.isPhysicalDevice = true
        var none = inputs()
        none.simulatorUDID = ""

        #expect(ActionContextPolicy.make(inputs()).environment["DEVHUB_SIMULATOR_KIND"] == "simulator")
        #expect(ActionContextPolicy.make(device).environment["DEVHUB_SIMULATOR_KIND"] == "device")
        #expect(ActionContextPolicy.make(none).environment["DEVHUB_SIMULATOR_KIND"] == "")
    }
}
