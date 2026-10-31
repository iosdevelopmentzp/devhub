import Foundation
import DevHubUI

struct TestRunPanelModel: Equatable {
    var title: String
    var detail: String?
    var icon: String
    var tint: Tint
    var isRunning: Bool
    var step: String?
    var failuresTitle: String?
    var failures: [TestFailureRowModel]
    var issuesTitle: String?
    var issues: [BuildIssueRowModel]
    var resultBundlePath: String?
    var canRunAgain: Bool
    var canFix: Bool

    static let preview = TestRunPanelModel(
        title: "Tests failed · ExampleApp",
        detail: "11 passed · 1 failed · 1 skipped · 4.2 s · iPhone 16 Pro",
        icon: "xmark.diamond.fill",
        tint: .red,
        isRunning: false,
        step: nil,
        failuresTitle: "1 failed test",
        failures: [.preview],
        issuesTitle: nil,
        issues: [],
        resultBundlePath: "/tmp/DevHub-tests/ExampleApp.xcresult",
        canRunAgain: true,
        canFix: true
    )
}
