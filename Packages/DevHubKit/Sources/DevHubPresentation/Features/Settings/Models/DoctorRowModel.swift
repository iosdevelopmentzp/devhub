import Foundation
import DevHubDomain
import DevHubUI

struct DoctorRowModel: Identifiable, Equatable {
    let id: String
    var name: String
    var purpose: String
    var stateText: String
    var stateTint: Tint
    var icon: String
    var path: String?
    var installCommand: String?

    static let preview = DoctorRowMapper.model(for: ToolStatus(tool: DoctorPolicy.tools[0], path: "/usr/bin/git", version: "2.50.1"))
}
