import Foundation

package struct MockRelaunchRequest: Sendable {
    package var udid: String
    package var bundleID: String
    package var plan: LaunchPlan
    package var mode: MockMode
    package var set: MockSet?

    package init(
        udid: String,
        bundleID: String,
        plan: LaunchPlan,
        mode: MockMode,
        set: MockSet?
    ) {
        self.udid = udid
        self.bundleID = bundleID
        self.plan = plan
        self.mode = mode
        self.set = set
    }
}
