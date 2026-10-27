import DevHubDomain
import DevHubUI

enum StatusItemState: Equatable {
    case idle
    case building
    case failed
    case awake

    static func state(isBuilding: Bool, hasUnseenFailure: Bool, isKeepingAwake: Bool) -> StatusItemState {
        if isBuilding { return .building }
        if hasUnseenFailure { return .failed }
        return isKeepingAwake ? .awake : .idle
    }

    var symbolName: String {
        switch self {
        case .idle: "hammer.fill"
        case .building: "hammer.circle.fill"
        case .failed: "hammer.fill"
        case .awake: "cup.and.saucer.fill"
        }
    }

    var showsFailureDot: Bool {
        self == .failed
    }
}
