enum WindowPresence: Equatable {
    case closed
    case minimized
    case otherDesktop
    case behind
    case front

    static func presence(isVisible: Bool, isMinimized: Bool, isOnActiveSpace: Bool, isAppActive: Bool, isMain: Bool) -> WindowPresence {
        if isMinimized {
            return .minimized
        }
        guard isVisible else { return .closed }
        guard isOnActiveSpace else { return .otherDesktop }
        return isAppActive && isMain ? .front : .behind
    }
}
