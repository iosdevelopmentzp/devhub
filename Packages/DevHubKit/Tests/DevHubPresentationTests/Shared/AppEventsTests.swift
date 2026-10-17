import Testing
@testable import DevHubPresentation

@Suite struct AppEventsTests {
    @Test func handlersRunInSubscriptionOrder() {
        let events = AppEvents()
        let log = Log()
        let tokens = [
            events.subscribe { log.items.append("first \($0)") },
            events.subscribe { log.items.append("second \($0)") },
            events.subscribe { log.items.append("third \($0)") }
        ]

        events.post(.branchesChanged)

        #expect(log.items == ["first branchesChanged", "second branchesChanged", "third branchesChanged"])
        withExtendedLifetime(tokens) {}
    }

    @Test func releasedTokenUnsubscribes() {
        let events = AppEvents()
        let log = Log()
        let kept = events.subscribe { log.items.append("kept \($0)") }
        var released: SubscriptionToken? = events.subscribe { log.items.append("released \($0)") }

        events.post(.projectChanged)
        #expect(released != nil)
        released = nil
        events.post(.worktreesChanged)

        #expect(log.items == ["kept projectChanged", "released projectChanged", "kept worktreesChanged"])
        withExtendedLifetime(kept) {}
    }

    @Test func aHandlerThatOwnsAnotherTokenCanBeReleased() {
        let events = AppEvents()
        let log = Log()
        var outer: SubscriptionToken?
        do {
            let inner = events.subscribe { log.items.append("inner \($0)") }
            outer = events.subscribe { _ in withExtendedLifetime(inner) {} }
        }

        events.post(.projectChanged)
        outer = nil
        events.post(.worktreesChanged)

        #expect(outer == nil)
        #expect(log.items == ["inner projectChanged"])
    }

    @Test func postingInsideHandlerDeliversToEveryHandler() {
        let events = AppEvents()
        let log = Log()
        let tokens = [
            events.subscribe { event in
                log.items.append("first \(event)")
                guard case .projectChanged = event else { return }
                events.post(.branchesChanged)
            },
            events.subscribe { log.items.append("second \($0)") }
        ]

        events.post(.projectChanged)

        #expect(log.items == ["first projectChanged", "first branchesChanged", "second branchesChanged", "second projectChanged"])
        withExtendedLifetime(tokens) {}
    }

    @Test func eventPayloadReachesHandler() {
        let events = AppEvents()
        let log = Log()
        let token = events.subscribe { event in
            guard case .buildFinished(let simulatorID, let launchedDeviceID) = event else { return }
            log.items.append("\(simulatorID) \(String(describing: launchedDeviceID))")
        }

        events.post(.buildFinished(simulatorID: "sim-1", launchedDeviceID: .some(nil)))

        #expect(log.items == ["sim-1 Optional(nil)"])
        withExtendedLifetime(token) {}
    }
}

private final class Log {
    var items: [String] = []
}
