import DevHubDomain
import DevHubUI

enum StatusItemState: Equatable {
    case idle
    case building
    case failed

    static func state(isBuilding: Bool, hasUnseenFailure: Bool) -> StatusItemState {
        if isBuilding { return .building }
        return hasUnseenFailure ? .failed : .idle
    }

    var symbolName: String {
        switch self {
        case .idle: "hammer.fill"
        case .building: "hammer.circle.fill"
        case .failed: "hammer.fill"
        }
    }

    var showsFailureDot: Bool {
        self == .failed
    }
}
