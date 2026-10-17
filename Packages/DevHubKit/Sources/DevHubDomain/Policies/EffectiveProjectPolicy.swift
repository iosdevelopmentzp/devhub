import Foundation

package enum EffectiveProjectPolicy {
    package static let defaultConfiguration = "Debug"

    package static func resolve(config: ProjectConfig, project: Project, detectedSchemes: [String], detectedBaseBranch: String?) -> EffectiveProject {
        let projectScheme = meaningful(project.scheme)
        let schemes = config.visibleSchemes(detected: detectedSchemes.isEmpty ? projectScheme.map { [$0] } ?? [] : detectedSchemes)
        let scheme = config.xcode?.scheme ?? projectScheme.flatMap { schemes.contains($0) ? $0 : nil } ?? schemes.first
        let configuration = config.xcode?.configuration ?? defaultConfiguration
        return EffectiveProject(
            name: config.name ?? project.name,
            kind: config.kind ?? (scheme == nil ? .command : .xcode),
            schemes: schemes,
            scheme: scheme,
            configuration: configuration,
            baseBranch: config.git?.baseBranch ?? detectedBaseBranch ?? GitSettingsPolicy.baseRef(remote: GitSettingsPolicy.settings(for: config).remote),
            bundleID: config.bundleID(scheme: scheme, configuration: configuration, detected: meaningful(project.bundleID))
        )
    }

    private static func meaningful(_ value: String) -> String? {
        let trimmed = value.trimmed
        return trimmed.isEmpty || trimmed == "—" ? nil : trimmed
    }
}
