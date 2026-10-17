import Foundation

@MainActor
struct ActionContextBuilder {
    let session: ProjectSession
    let config: ConfigStore

    func make(configDir: String, item: ActionItemContext, inputs: [String: String]) -> ActionContext {
        let project = session.project
        let effective = config.effective
        var context = ActionContext()
        context.projectPath = project?.path ?? ""
        context.projectName = effective?.name ?? project?.name ?? ""
        context.checkoutPath = session.activeCheckoutPath ?? ""
        context.mainPath = project?.path ?? ""
        context.branch = item.branch ?? session.activeBranch ?? ""
        context.baseBranch = effective?.baseBranch ?? ""
        context.scheme = effective?.scheme ?? ""
        context.configuration = effective?.configuration ?? ""
        context.bundleID = effective?.bundleID ?? ""
        context.simulatorUDID = item.simulatorUDID ?? session.target?.id ?? ""
        context.simulatorName = item.simulatorName ?? session.target?.name ?? ""
        context.appPath = session.lastAppPath ?? ""
        context.worktreePath = item.worktreePath ?? ""
        context.configDir = configDir
        context.rowID = item.rowID ?? ""
        context.version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        context.inputs = inputs
        return context
    }

    func defaultValue(for input: ActionInput) -> String {
        let value = input.defaultValue ?? ""
        switch input.type {
        case .branch: return value == "current" ? session.activeBranch ?? "" : value
        case .simulator: return value == "target" ? session.target?.id ?? "" : value
        case .toggle: return value == "true" ? "true" : "false"
        case .scheme: return value.isEmpty ? config.effective?.scheme ?? "" : value
        case .choice: return value.isEmpty ? input.options?.first?.value ?? "" : value
        case .text, .number, .worktree, .file, .folder: return value
        }
    }

    func workingFolder(_ cwd: String?, context: ActionContext) -> String {
        switch cwd ?? "checkout" {
        case "checkout": return context.checkoutPath
        case "main": return context.mainPath
        case "project": return context.projectPath
        case let path:
            let expanded = (PlaceholderExpander.expand(path, values: context.placeholders, encodesForURL: false) as NSString).expandingTildeInPath
            return expanded.hasPrefix("/") ? expanded : context.projectPath + "/" + expanded
        }
    }
}
