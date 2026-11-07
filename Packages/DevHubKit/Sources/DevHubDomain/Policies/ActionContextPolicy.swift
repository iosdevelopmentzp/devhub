import Foundation

package enum ActionContextPolicy {
    package static func make(_ inputs: ActionContextInputs) -> ActionContext {
        var context = ActionContext()
        context.projectPath = inputs.projectPath
        context.projectName = inputs.effective?.name ?? inputs.projectName
        context.checkoutPath = inputs.checkoutPath
        context.mainPath = inputs.projectPath
        context.branch = inputs.item.branch ?? inputs.branch
        context.baseBranch = inputs.effective?.baseBranch ?? ""
        context.scheme = inputs.effective?.scheme ?? ""
        context.configuration = inputs.effective?.configuration ?? ""
        context.bundleID = inputs.item.bundleID ?? inputs.effective?.bundleID ?? ""
        context.simulatorUDID = inputs.item.simulatorUDID ?? inputs.simulatorUDID
        context.simulatorName = inputs.item.simulatorName ?? inputs.simulatorName
        context.simulatorState = stateText(inputs.simulatorState)
        context.simulatorKind = inputs.simulatorUDID.isEmpty && inputs.item.simulatorUDID == nil ? "" : (inputs.isPhysicalDevice ? "device" : "simulator")
        context.appPath = inputs.appPath
        context.worktreePath = inputs.item.worktreePath ?? ""
        context.configDir = inputs.configDir
        context.rowID = inputs.item.rowID ?? ""
        context.version = inputs.version
        context.pullRequestNumber = inputs.item.pullRequestNumber.map(String.init) ?? ""
        context.pullRequestURL = inputs.item.pullRequestURL?.absoluteString ?? ""
        context.profile = inputs.profileID
        context.host = inputs.hostKind?.rawValue ?? ""
        context.appContainer = inputs.containers.app
        context.dataContainer = inputs.containers.data
        context.groupContainers = inputs.containers.groups.map { "\($0.name)\t\($0.path)" }.joined(separator: "\n")
        context.inputs = inputs.inputs
        return context
    }

    package static func defaultValue(for input: ActionInput, branch: String, simulatorUDID: String, scheme: String) -> String {
        let value = input.defaultValue ?? ""
        switch input.type {
        case .branch: return value == "current" ? branch : value
        case .simulator: return value == "target" ? simulatorUDID : value
        case .toggle: return value == "true" ? "true" : "false"
        case .scheme: return value.isEmpty ? scheme : value
        case .choice: return value.isEmpty ? input.options?.first?.value ?? "" : value
        case .text, .number, .worktree, .file, .folder: return value
        }
    }

    package static func workingFolder(_ cwd: String?, context: ActionContext, home: String) -> String {
        switch cwd ?? "checkout" {
        case "checkout": return context.checkoutPath
        case "main": return context.mainPath
        case "project": return context.projectPath
        case let path:
            var expanded = PlaceholderExpander.expand(path, values: context.placeholders, encodesForURL: false)
            if expanded == "~" || expanded.hasPrefix("~/") {
                expanded = home + expanded.dropFirst()
            }
            return expanded.hasPrefix("/") ? expanded : context.projectPath + "/" + expanded
        }
    }

    private static func stateText(_ state: Simulator.State?) -> String {
        switch state {
        case .booted: "booted"
        case .shutdown: "shutdown"
        case .booting: "booting"
        case .shuttingDown: "shutting-down"
        case nil: ""
        }
    }
}
