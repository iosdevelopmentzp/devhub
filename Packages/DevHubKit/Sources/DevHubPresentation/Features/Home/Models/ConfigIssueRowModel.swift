import Foundation
import DevHubDomain
import DevHubUI

struct ConfigIssueRowModel: Identifiable, Equatable {
    let id: String
    var location: String
    var message: String

    static let preview = ConfigIssueRowModel(id: "1", location: "project: actions/clean.json", message: "run: this key is required.")
}
