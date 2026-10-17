import Foundation
import Observation

@MainActor
@Observable
final class Navigator {
    var selectedID: String {
        didSet { preferences.set(selectedID, for: .selectedTab) }
    }

    @ObservationIgnored private let preferences: AppPreferences

    init(preferences: AppPreferences) {
        self.preferences = preferences
        selectedID = preferences.string(.selectedTab) ?? "home"
    }

    func show(_ id: String) {
        selectedID = id
    }
}
