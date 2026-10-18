import Foundation
import DevHubDomain

enum AppURLSchemeParser {
    static func schemes(in info: [String: Any]?) -> [String] {
        let types = info?["CFBundleURLTypes"] as? [[String: Any]] ?? []
        var schemes: [String] = []
        for type in types {
            for scheme in type["CFBundleURLSchemes"] as? [String] ?? [] where scheme.trimmed.isEmpty == false && schemes.contains(scheme) == false {
                schemes.append(scheme)
            }
        }
        return schemes
    }
}
