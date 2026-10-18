import Foundation

package enum MockUpstreamPolicy {

    package static func upstream(for profile: LaunchProfile?) throws -> URL {
        guard let profile else { throw MockServerError.noProfile }
        guard profile.isProduction == false else { throw MockServerError.productionRefused(profile: profile.title) }
        guard let value = profile.upstream?.trimmed,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              url.host?.isEmpty == false else {
            throw MockServerError.noUpstream(profile: profile.title)
        }
        return url
    }

    package static func profile(ofHost host: String, in profiles: [LaunchProfile]) -> LaunchProfile? {
        profiles.first { $0.upstream.flatMap { URL(string: $0.trimmed)?.host } == host }
    }
}
