import DevHubDomain
import DevHubTestSupport

enum LaunchConfigSample {
    static let identity = LaunchIdentityConfig(variable: "APP_DEVICE_ID")
    static let staging = LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], upstream: "https://api.staging.example.com")
    static let dev = LaunchProfile(id: "dev", title: "Dev", upstream: "https://api.dev.example.com")
    static let production = LaunchProfile(id: "production", title: "Production", upstream: "https://api.example.com", production: true)

    static func resolved(
        identity: LaunchIdentityConfig? = identity,
        profiles: [LaunchProfile]? = [staging, dev, production],
        baseURLVariable: String? = "APP_BASE_URL"
    ) -> ResolvedConfig {
        ResolvedConfig(
            project: ProjectConfig(launch: LaunchConfig(profiles: profiles, identity: identity), network: NetworkConfig(baseURLVariable: baseURLVariable)),
            actions: [],
            tabs: [],
            issues: [],
            layers: []
        )
    }
}
