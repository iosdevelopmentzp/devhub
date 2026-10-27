import Foundation

package enum SimulatorSetting: Hashable, Sendable {
    case appearance(SimulatorAppearance)
    case textSize(SimulatorTextSize)
    case cleanStatusBar
    case resetStatusBar
    case location(latitude: Double, longitude: Double)
    case clearLocation
    case language(code: String, locale: String)
    case privacy(PrivacyChange, service: PrivacyService, bundleID: String)
}
