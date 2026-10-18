import Foundation

package extension ProjectConfig {
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

    func knownBundleIDs(detected: String?) -> Set<String> {
        Set([xcode?.bundleID, detected].compactMap { $0 } + (xcode?.bundleIDs?.values.map { $0 } ?? []))
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
