import Foundation
import DevHubUI

struct BuildIssueRowModel: Identifiable, Equatable {
    let id: Int
    var icon: String
    var tint: Tint
    var location: String?
    var message: String
    var path: String?
    var line: Int?
    var hint: String

    static let preview = BuildIssueRowModel(
        id: 0,
        icon: "xmark.octagon.fill",
        tint: .red,
        location: "LoginView.swift:42",
        message: "cannot find 'viewModel' in scope",
        path: "/Users/dev/Projects/ExampleApp/LoginView.swift",
        line: 42,
        hint: "Open /Users/dev/Projects/ExampleApp/LoginView.swift at line 42"
    )
}
