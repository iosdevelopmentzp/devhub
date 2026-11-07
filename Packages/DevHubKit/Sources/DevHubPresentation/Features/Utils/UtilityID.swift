import DevHubDomain
import DevHubUI

enum UtilityID: String, CaseIterable, Hashable {
    case compressVideo
    case tickets

    var title: String {
        switch self {
        case .compressVideo: "Compress Video"
        case .tickets: "Tickets"
        }
    }

    var systemImage: String {
        switch self {
        case .compressVideo: "film"
        case .tickets: "ticket"
        }
    }

    var searchPrompt: String {
        switch self {
        case .compressVideo: "Filter videos"
        case .tickets: "Filter tickets"
        }
    }
}
