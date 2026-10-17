import Foundation
import DevHubDomain
import DevHubUI

struct IdentitySummaryModel: Equatable {
    var isApplying: Bool
    var applyingText: String
    var environmentTag: TagModel
    var deviceAlias: String?
    var deviceID: String?
    var userText: String?
    var userCopyValue: String?
    var userCopyLabel: String?
    var userIcon: String
    var notLoggedInText: String?
    var nextDeviceTag: TagModel?
    var mockTag: TagModel?

    static let preview = IdentitySummaryModel(
        isApplying: false,
        applyingText: "Applying device settings…",
        environmentTag: TagModel("qa", tint: .teal, hint: "Environment stored in the app"),
        deviceAlias: "Sam QA",
        deviceID: "devhub-3f9a1c2e",
        userText: "Sam Test · u_48213",
        userCopyValue: "u_48213",
        userCopyLabel: "user u_48213",
        userIcon: "person.fill",
        notLoggedInText: nil,
        nextDeviceTag: TagModel("next: Bob QA · devhub-77b0e4d1", tint: .orange, hint: "The next launch from DevHub uses this device ID"),
        mockTag: TagModel("passthrough :52001 → api-qa.example.com", tint: .teal, systemImage: "network", hint: "The app launched from DevHub talks to 127.0.0.1:52001; DevHub forwards to api-qa.example.com")
    )
}
