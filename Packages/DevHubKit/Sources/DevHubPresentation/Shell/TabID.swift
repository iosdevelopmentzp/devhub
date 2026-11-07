import DevHubDomain
import DevHubUI

enum TabID: Hashable {
    case feature(FeatureID)
    case utility(UtilityID)
    case custom(String)

    private static let customPrefix = "tab."
    private static let utilityPrefix = "utility."

    init?(rawValue: String) {
        if rawValue.hasPrefix(Self.customPrefix) {
            let id = String(rawValue.dropFirst(Self.customPrefix.count))
            guard id.isEmpty == false else { return nil }
            self = .custom(id)
            return
        }
        if rawValue.hasPrefix(Self.utilityPrefix) {
            guard let utility = UtilityID(rawValue: String(rawValue.dropFirst(Self.utilityPrefix.count))) else { return nil }
            self = .utility(utility)
            return
        }
        guard let feature = FeatureID(rawValue: rawValue) else { return nil }
        self = .feature(feature)
    }

    var rawValue: String {
        switch self {
        case .feature(let id): id.rawValue
        case .utility(let id): Self.utilityPrefix + id.rawValue
        case .custom(let id): Self.customPrefix + id
        }
    }
}
