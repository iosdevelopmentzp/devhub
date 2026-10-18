import Foundation
import DevHubDomain
import DevHubUI

struct LaunchProfileModel: Equatable {
    struct Option: Identifiable, Equatable {
        let id: LaunchProfile.ID
        let title: String
        let isProduction: Bool
    }

    var options: [Option]
    var selectedID: LaunchProfile.ID
    var usesSegments: Bool
    var summary: String
    var details: String
    var productionTag: TagModel?

    static let preview = LaunchProfileModel(
        options: [Option(id: "staging", title: "Staging", isProduction: false), Option(id: "production", title: "Production", isProduction: true)],
        selectedID: "staging",
        usesSegments: true,
        summary: "API_ENV=staging · 1 default",
        details: "env API_ENV=staging\ndefault group.com.example.app · environment = staging",
        productionTag: nil
    )
}
