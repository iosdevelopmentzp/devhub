import Foundation
import DevHubDomain
import DevHubUI

struct IdentitySummaryModel: Equatable {
    var isApplying: Bool
    var applyingText: String
    var profileTag: TagModel?
    var deviceAlias: String?
    var deviceID: String?
    var userText: String?
    var userIcon: String
    var nextDeviceTag: TagModel?
    var mockTag: TagModel?

    static let preview = IdentityPanelMapper.summary(context: .preview, mockState: nil)
}
