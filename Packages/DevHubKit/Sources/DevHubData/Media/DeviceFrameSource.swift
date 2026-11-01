import Foundation
import CoreGraphics
import DevHubDomain

struct DeviceFrameSource: Sendable {
    var folder: URL
    var chrome: DeviceChrome
    var screen: CGSize
    var scale: Double
}
