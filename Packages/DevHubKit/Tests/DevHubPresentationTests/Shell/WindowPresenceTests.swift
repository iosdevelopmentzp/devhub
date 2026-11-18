import Testing
@testable import DevHubPresentation

@Suite struct WindowPresenceTests {
    @Test func aWindowThatIsNotOrderedInIsClosed() {
        #expect(WindowPresence.presence(isVisible: false, isMinimized: false, isOnActiveSpace: false, isAppActive: true, isMain: false) == .closed)
    }

    @Test func aMinimizedWindowIsMinimizedWhateverElseIsTrue() {
        #expect(WindowPresence.presence(isVisible: false, isMinimized: true, isOnActiveSpace: false, isAppActive: true, isMain: true) == .minimized)
    }

    @Test func aVisibleWindowOnAnotherDesktopIsOnTheOtherDesktop() {
        #expect(WindowPresence.presence(isVisible: true, isMinimized: false, isOnActiveSpace: false, isAppActive: true, isMain: true) == .otherDesktop)
    }

    @Test(arguments: [
        (false, true),
        (true, false),
        (false, false),
    ])
    func aWindowOnThisDesktopIsBehindUnlessTheAppIsActiveAndItIsMain(isAppActive: Bool, isMain: Bool) {
        #expect(WindowPresence.presence(isVisible: true, isMinimized: false, isOnActiveSpace: true, isAppActive: isAppActive, isMain: isMain) == .behind)
    }

    @Test func theMainWindowOfTheActiveAppOnThisDesktopIsInFront() {
        #expect(WindowPresence.presence(isVisible: true, isMinimized: false, isOnActiveSpace: true, isAppActive: true, isMain: true) == .front)
    }
}
