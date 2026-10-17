import Foundation
@testable import DevHubDomain

enum ConfigFixture {
    static let projectJSON = """
    {
      "name": "Example App",
      "kind": "xcode",
      "xcode": { "scheme": "ExampleApp", "schemes": ["ExampleApp", "ExampleWidget"], "bundleIDs": { "ExampleApp/Release": "com.example.app" } },
      "git": { "baseBranch": "origin/main" },
      "launch": { "profiles": [ { "id": "staging", "title": "Staging", "defaults": [ { "suite": "group.com.example.app", "key": "count", "value": 3 } ] } ] },
      "home": { "quickActions": ["builtin.buildRun", "clean"] }
    }
    """

    static let cleanAction = """
    { "id": "clean", "title": "Clean", "run": { "script": "scripts/clean.sh" }, "placements": ["git.pills"] }
    """

    static let twoActions = """
    [
      { "id": "open-ci", "title": "Open CI", "run": { "open": "https://ci.example.com/{branch}" } },
      { "id": "broken", "title": "Broken" }
    ]
    """

    static let header = """
    #!/bin/zsh
    # devhub: title = Regenerate
    # devhub: subtitle = Runs the generator
    # devhub: tint = purple
    # devhub: placements = home.scripts, git.pills
    # devhub: input = target, Target, choice, app | widget
    # devhub: input = verbose, Verbose, toggle, true
    # devhub: refresh = git, nothing
    # devhub: colour = blue
    echo done
    """

    static let tab = """
    { "id": "qa", "title": "QA", "sections": [ { "title": "Devices", "source": { "script": "scripts/list.sh", "refresh": 30 } } ] }
    """

    static func layer(_ layer: ConfigLayer, project: String? = nil, actions: [String] = [], scripts: [ScriptFile] = [], tabs: [String] = []) -> ConfigLayerFiles {
        ConfigLayerFiles(
            layer: layer,
            directory: "/\(layer.rawValue)/.devhub",
            exists: true,
            projectFile: project.map { ConfigFile(name: "project.json", text: $0) },
            actionFiles: actions.enumerated().map { ConfigFile(name: "actions/\($0.offset).json", text: $0.element) },
            scriptFiles: scripts,
            tabFiles: tabs.enumerated().map { ConfigFile(name: "tabs/\($0.offset).json", text: $0.element) }
        )
    }
}
