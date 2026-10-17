import Foundation

package struct ScriptViewAction: Codable, Hashable, Sendable {
    package var title: String
    package var run: ActionRun
    package var confirm: String? = nil

    package init(
        title: String,
        run: ActionRun,
        confirm: String? = nil
    ) {
        self.title = title
        self.run = run
        self.confirm = confirm
    }
}
