import Foundation

package enum MockUpstreamPolicy {

    package static func upstream(for profile: LaunchProfile?) throws -> MockUpstream {
        guard let profile else { throw MockServerError.noProfile }
        guard profile.isProduction == false else { throw MockServerError.productionRefused(profile: profile.title) }
        guard let url = profile.upstream.flatMap(serverURL) else {
            throw MockServerError.noUpstream(profile: profile.title)
        }
        let routes = try (profile.routes ?? []).map { route in
            let path = route.path.trimmed
            guard path.hasPrefix("/"), let upstream = serverURL(route.upstream) else {
                throw MockServerError.badRoute(profile: profile.title, path: route.path)
            }
            return MockRoute(path: path, upstream: upstream)
        }
        return MockUpstream(url: url, routes: routes)
    }

    package static func profile(ofHost host: String, in profiles: [LaunchProfile]) -> LaunchProfile? {
        profiles.first { $0.upstream.flatMap { URL(string: $0.trimmed)?.host } == host }
    }

    private static func serverURL(_ value: String) -> URL? {
        guard let url = URL(string: value.trimmed),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              url.host?.isEmpty == false else { return nil }
        return url
    }
}
