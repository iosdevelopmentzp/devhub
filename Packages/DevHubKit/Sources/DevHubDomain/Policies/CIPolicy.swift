import Foundation

package enum CIPolicy {
    package static let minimumVersion = 1

    package static func provider(config: CIConfig?, hasCircleCIConfig: Bool) -> CIProvider? {
        switch config?.kind?.lowercased() {
        case "circleci": .circleci
        case "none": nil
        case .some: nil
        case nil: hasCircleCIConfig ? .circleci : nil
        }
    }

    package static func circleCIConfigPath(checkoutPath: String) -> String {
        (checkoutPath as NSString).appendingPathComponent(".circleci/config.yml")
    }

    package static func isSupported(version: String) -> Bool {
        guard let major = version.split(separator: ".").first.flatMap({ Int($0.filter(\.isNumber)) }) else { return false }
        return major >= minimumVersion
    }

    package static func installCommand(for state: CIToolState) -> String? {
        guard state.isInstalled else { return "brew install circleci && circleci auth login" }
        if let version = state.version, isSupported(version: version) == false {
            return "brew upgrade circleci"
        }
        guard state.isLoggedIn else { return "circleci auth login" }
        return nil
    }
}
