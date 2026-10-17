import Foundation
import DevHubDomain
import DevHubUI

struct LaunchIdentityModel: Equatable {
    var environments: [String]
    var savedDeviceIDs: [SavedDeviceIDModel]
    var canEditAlias: Bool
    var aliasPlaceholder: String
    var productionTag: TagModel?

    static let preview = LaunchIdentityModel(
        environments: ["qa", "dev", "prod"],
        savedDeviceIDs: [
            SavedDeviceIDModel(id: "devhub-3f9a1c2e", title: "Sam QA · devhub-3f9a1c2e"),
            SavedDeviceIDModel(id: "devhub-77b0e4d1", title: "devhub-77b0e4d1")
        ],
        canEditAlias: true,
        aliasPlaceholder: "a name for this device ID",
        productionTag: nil
    )
}
