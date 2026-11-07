import Foundation
import DevHubDomain
import DevHubUI

struct ConfigCopyRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var projectPath: String
    var tabID: String?
    var actionID: String
    var title: String
    var text: String
    var open: String?
    var date: Date
}
