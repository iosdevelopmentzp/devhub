import Foundation

package struct LaunchPlan: Hashable, Sendable {
    package static let none = LaunchPlan(profile: nil, identityConfig: nil, identity: nil, baseURLVariable: nil)

    package var profile: LaunchProfile?
    package var identityConfig: LaunchIdentityConfig?
    package var identity: String?
    package var baseURLVariable: String?

    package init(
        profile: LaunchProfile?,
        identityConfig: LaunchIdentityConfig?,
        identity: String?,
        baseURLVariable: String?
    ) {
        self.profile = profile
        self.identityConfig = identityConfig
        self.identity = identity
        self.baseURLVariable = baseURLVariable
    }

    package var environment: [String: String] {
        var values = profile?.env ?? [:]
        guard let identityConfig else { return values }
        if let identity {
            values[identityConfig.variable] = identity
        }
        if let kept = identityConfig.keptVariable {
            values[kept] = identity ?? ""
        }
        return values
    }

    package var arguments: [String] {
        (identityConfig?.args ?? []) + (profile?.args ?? [])
    }

    package var defaults: [ProfileDefault] {
        profile?.defaults ?? []
    }

    package func record(bundleID: String, baseURL: String?, date: Date) -> LaunchRecord {
        LaunchRecord(bundleID: bundleID, profileID: profile?.id, identity: identity, baseURL: baseURL, date: date)
    }
}
