import DevHubDomain
import DevHubUI

enum TabID: Hashable {
    case feature(FeatureID)
    case custom(String)

    private static let customPrefix = "tab."

    init?(rawValue: String) {
        if rawValue.hasPrefix(Self.customPrefix) {
            let id = String(rawValue.dropFirst(Self.customPrefix.count))
            guard id.isEmpty == false else { return nil }
            self = .custom(id)
            return
        }
        guard let feature = FeatureID(rawValue: rawValue) else { return nil }
        self = .feature(feature)
    }

    var rawValue: String {
        switch self {
        case .feature(let id): id.rawValue
        case .custom(let id): Self.customPrefix + id
        }
    }
}
