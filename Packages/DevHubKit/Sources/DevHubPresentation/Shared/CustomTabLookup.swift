import Foundation
import DevHubDomain

@MainActor
protocol CustomTabLookup: AnyObject {
    var customTabs: [TabConfig] { get }
}
