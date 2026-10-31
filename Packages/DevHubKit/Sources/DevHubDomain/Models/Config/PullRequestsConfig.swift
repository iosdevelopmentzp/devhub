import Foundation

package struct PullRequestsConfig: Codable, Hashable, Sendable {
    package var targets: [String]? = nil
    package var template: String? = nil
    package var staleDays: Int? = nil
    package var hiddenFiles: [String]? = nil
    package var defaults: PullRequestDefaultsConfig? = nil

    package init(targets: [String]? = nil, template: String? = nil, staleDays: Int? = nil, hiddenFiles: [String]? = nil, defaults: PullRequestDefaultsConfig? = nil) {
        self.targets = targets
        self.template = template
        self.staleDays = staleDays
        self.hiddenFiles = hiddenFiles
        self.defaults = defaults
    }
}
