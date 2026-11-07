import DevHubDomain
import DevHubUI

enum StatusItemState: Equatable {
    case idle
    case building
    case failed
    case ciFailed
    case ciWaiting
    case awake

    static func state(isBuilding: Bool, hasUnseenFailure: Bool, isCIFailed: Bool, isCIWaiting: Bool, isKeepingAwake: Bool) -> StatusItemState {
        if isBuilding { return .building }
        if hasUnseenFailure { return .failed }
        if isCIFailed { return .ciFailed }
        if isCIWaiting { return .ciWaiting }
        return isKeepingAwake ? .awake : .idle
    }

    var symbolName: String {
        switch self {
        case .idle, .failed, .ciFailed, .ciWaiting: "hammer.fill"
        case .building: "hammer.circle.fill"
        case .awake: "cup.and.saucer.fill"
        }
    }

    var dotTint: Tint? {
        switch self {
        case .failed, .ciFailed: .red
        case .ciWaiting: .orange
        case .idle, .building, .awake: nil
        }
    }

    var showsFailureDot: Bool {
        dotTint != nil
    }
}
