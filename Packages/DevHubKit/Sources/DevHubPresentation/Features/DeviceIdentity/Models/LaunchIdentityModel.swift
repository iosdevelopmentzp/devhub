import Foundation
import DevHubDomain
import DevHubUI

struct LaunchIdentityModel: Equatable {
    var idPrefix: String
    var savedDeviceIDs: [SavedDeviceIDModel]
    var canEditAlias: Bool
    var aliasPlaceholder: String

    static let preview = IdentityPanelMapper.launch(context: .preview)
}
