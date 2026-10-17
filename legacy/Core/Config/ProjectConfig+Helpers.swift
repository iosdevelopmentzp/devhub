import Foundation

nonisolated extension ProjectConfig {
    func bundleID(scheme: String?, configuration: String?, detected: String?) -> String? {
        let table = xcode?.bundleIDs ?? [:]
        if let scheme, let configuration, let exact = table["\(scheme)/\(configuration)"] {
            return exact
        }
        if let scheme, let byScheme = table[scheme] {
            return byScheme
        }
        return xcode?.bundleID ?? detected
    }

    func visibleSchemes(detected: [String]) -> [String] {
        guard let listed = xcode?.schemes, listed.isEmpty == false else { return detected }
        return listed
    }

    var quickActionIDs: [String]? {
        guard let listed = home?.quickActions, listed.isEmpty == false else { return nil }
        return listed
    }
}

nonisolated struct EffectiveProject: Hashable, Sendable {
    var name: String
    var kind: ProjectKind
    var container: String?
    var schemes: [String]
    var scheme: String?
    var configuration: String
    var baseBranch: String
    var bundleID: String?

    init(config: ProjectConfig, detection: ProjectDetection?, folderName: String) {
        let detected = detection ?? .empty
        let visible = config.visibleSchemes(detected: detected.schemes)
        name = config.name ?? folderName
        kind = config.kind ?? detected.kind
        container = config.xcode?.container ?? detected.container
        schemes = visible
        scheme = config.xcode?.scheme ?? visible.first
        configuration = config.xcode?.configuration ?? "Debug"
        baseBranch = config.git?.baseBranch ?? detected.baseBranch ?? "origin/main"
        bundleID = config.bundleID(scheme: scheme, configuration: configuration, detected: detected.bundleID)
    }
}
