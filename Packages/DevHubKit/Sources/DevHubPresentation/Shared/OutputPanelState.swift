import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class OutputPanelState {
    static let defaultHeight: CGFloat = 260
    static let minimumHeight: CGFloat = 120
    static let reservedWindowHeight: CGFloat = 320

    var isVisible: Bool {
        didSet { store.set(isVisible, forKey: Keys.visible) }
    }
    var showsReads: Bool {
        didSet { store.set(showsReads, forKey: Keys.showsReads) }
    }
    var followsOutput: Bool {
        didSet { store.set(followsOutput ? "on" : "off", forKey: Keys.follows) }
    }
    var opensOnFailure: Bool {
        didSet { store.set(opensOnFailure, forKey: Keys.opensOnFailure) }
    }
    private(set) var height: CGFloat {
        didSet { store.set([Double(height)], forKey: Keys.height) }
    }

    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(store: any KeyValueStore, events: AppEvents) {
        self.store = store
        isVisible = store.bool(forKey: Keys.visible)
        showsReads = store.bool(forKey: Keys.showsReads)
        followsOutput = store.string(forKey: Keys.follows) != "off"
        opensOnFailure = store.bool(forKey: Keys.opensOnFailure)
        height = store.doubles(forKey: Keys.height)?.first.map { max(CGFloat($0), Self.minimumHeight) } ?? Self.defaultHeight
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .commandFailed = event, opensOnFailure else { return }
            isVisible = true
        }
    }

    func height(inWindowOfHeight windowHeight: CGFloat) -> CGFloat {
        min(height, Self.maximumHeight(inWindowOfHeight: windowHeight))
    }

    func resize(to proposed: CGFloat, inWindowOfHeight windowHeight: CGFloat) {
        let clamped = min(max(proposed, Self.minimumHeight), Self.maximumHeight(inWindowOfHeight: windowHeight)).rounded()
        guard clamped != height else { return }
        height = clamped
    }

    func resetHeight() {
        height = Self.defaultHeight
    }

    private static func maximumHeight(inWindowOfHeight windowHeight: CGFloat) -> CGFloat {
        max(windowHeight - reservedWindowHeight, minimumHeight)
    }

    private enum Keys {
        static let visible = "output.visible"
        static let showsReads = "output.showsReads"
        static let follows = "output.follows"
        static let opensOnFailure = "output.opensOnFailure"
        static let height = "output.height"
    }
}
