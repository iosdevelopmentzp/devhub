import Foundation

package enum UpstreamResolver {

    package static func upstream(environment: String?, config: DeviceIdentityConfig) throws -> URL {
        let name = (environment?.trimmed).flatMap { $0.isEmpty ? nil : $0.lowercased() } ?? config.defaultEnvironment.lowercased()
        guard name.hasPrefix("prod") == false else { throw MockServerError.prodNotSupported }
        guard let value = table(for: config)[name],
              let url = URL(string: value.trimmed),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              url.host?.isEmpty == false else {
            throw MockServerError.noUpstream(environment: name)
        }
        return url
    }

    package static func environmentName(ofHost host: String, config: DeviceIdentityConfig) -> String? {
        table(for: config).first { URL(string: $0.value.trimmed)?.host == host }?.key
    }

    package static func table(for config: DeviceIdentityConfig) -> [String: String] {
        config.mockUpstreams ?? [:]
    }
}
