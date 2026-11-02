import DevHubDomain
import DevHubUI

enum UtilityID: String, CaseIterable, Hashable {
    case compressVideo

    var title: String {
        switch self {
        case .compressVideo: "Compress Video"
        }
    }

    var systemImage: String {
        switch self {
        case .compressVideo: "film"
        }
    }
}
