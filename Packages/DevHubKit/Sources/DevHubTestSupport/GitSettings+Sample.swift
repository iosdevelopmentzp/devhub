import DevHubDomain

extension GitSettings {
    package static let withBootstrap: GitSettings = {
        var settings = GitSettings.standard
        settings.worktrees = WorktreeSettings(folder: nil, include: [], bootstrap: "scripts/bootstrap.sh", bootstrapMarker: "Pods")
        return settings
    }()
}
