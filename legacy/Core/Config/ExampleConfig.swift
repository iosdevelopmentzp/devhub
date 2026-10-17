import Foundation

nonisolated struct ExampleFile: Sendable {
    let path: String
    let isExecutable: Bool
    let content: String
}

nonisolated enum ExampleConfig {
    static var all: [ExampleFile] { documents + ExampleScripts.all }

    static let documents: [ExampleFile] = [
        ExampleFile(path: "README.md", isExecutable: false, content: #"""
# Example `.devhub/` folder

Copy this folder into a project as `.devhub/` and adjust the values. Every field is explained in `docs/extensions.md`.

- `project.json`: how the project builds and runs, base branch, worktree rules, launch profiles, log filter, Home grid order.
- `actions/`: buttons with placements, inputs and confirmation.
- `scripts/`: executables with a `# devhub:` header; they become rows on Home without a JSON file.
- `tabs/`: a custom tab built from actions and a source script.
"""#),
        ExampleFile(path: "actions/clean-derived-data.json", isExecutable: false, content: #"""
{
  "id": "clean-derived-data",
  "title": "Clean DerivedData",
  "subtitle": "Removes the DerivedData folder of this project",
  "icon": "trash",
  "tint": "red",
  "placements": ["home.quickActions", "git.pills"],
  "run": { "script": "scripts/clean-derived-data.sh" },
  "cwd": "checkout",
  "confirm": "Delete DerivedData for this checkout? The next build takes longer.",
  "refresh": ["worktrees"]
}
"""#),
        ExampleFile(path: "actions/open-ci.json", isExecutable: false, content: #"""
[
  {
    "id": "open-ci",
    "title": "Open CI",
    "subtitle": "Pipelines of the current branch",
    "icon": "play.rectangle",
    "tint": "blue",
    "placements": ["home.quickActions", "git.pills", "git.branchRow"],
    "run": { "open": "https://ci.example.com/pipelines?branch={branch}" }
  },
  {
    "id": "lint",
    "title": "Lint",
    "subtitle": "Runs the linter in the terminal",
    "icon": "checkmark.seal",
    "tint": "green",
    "placements": ["git.pills"],
    "run": { "terminal": "make lint" },
    "cwd": "checkout",
    "when": { "git": "dirty" }
  }
]
"""#),
        ExampleFile(path: "project.json", isExecutable: false, content: #"""
{
  "name": "Example App",
  "kind": "xcode",
  "xcode": {
    "container": "ExampleApp.xcworkspace",
    "scheme": "ExampleApp",
    "configuration": "Debug",
    "schemes": ["ExampleApp", "ExampleWidget"],
    "bundleIDs": { "ExampleApp": "com.example.app", "ExampleApp/Debug": "com.example.app.dev" }
  },
  "git": {
    "baseBranch": "origin/main",
    "commitPrefix": { "pattern": "^([A-Z]+-\\d+)", "format": "$1: " },
    "worktrees": {
      "folder": ".worktrees",
      "include": ["Config/Local.xcconfig"],
      "bootstrap": "Scripts/bootstrap.sh",
      "bootstrapMarker": "Pods"
    }
  },
  "launch": {
    "profiles": [
      { "id": "staging", "title": "Staging", "env": { "API_ENV": "staging" }, "defaults": [ { "suite": "group.com.example.app", "key": "environment", "value": "staging" } ] },
      { "id": "production", "title": "Production", "env": { "API_ENV": "production" }, "cleanInstall": true }
    ]
  },
  "logs": { "subsystem": "com.example.app" },
  "simulators": { "statusScript": "scripts/sim-status.sh" },
  "home": { "quickActions": ["builtin.buildRun", "builtin.runAttach", "clean-derived-data", "open-ci", "builtin.terminal", "builtin.copyBranch"] }
}
"""#),
        ExampleFile(path: "tabs/qa.json", isExecutable: false, content: #"""
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "sections": [
    { "title": "Project", "actions": ["clean-derived-data", "open-ci", "script:regenerate-resources"] },
    { "title": "Booted simulators", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
"""#)
    ]
}

nonisolated extension ExampleConfig {
    static func layerFiles(layer: ConfigLayer, directory: String) -> ConfigLayerFiles {
        var files = ConfigLayerFiles(layer: layer, directory: directory, exists: true)
        for example in all {
            let file = ConfigFile(name: example.path, text: example.content)
            if example.path == "project.json" {
                files.projectFile = file
            } else if example.path.hasPrefix("actions/") {
                files.actionFiles.append(file)
            } else if example.path.hasPrefix("tabs/") {
                files.tabFiles.append(file)
            } else if example.path.hasPrefix("scripts/") {
                files.scriptFiles.append(ScriptFile(name: example.path, head: example.content, isExecutable: true))
            }
        }
        return files
    }
}
