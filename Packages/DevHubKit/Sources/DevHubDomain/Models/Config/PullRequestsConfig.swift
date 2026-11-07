import Foundation

package struct PullRequestsConfig: Codable, Hashable, Sendable {
    package var targets: [String]? = nil
    package var template: String? = nil
    package var staleDays: Int? = nil
    package var hiddenFiles: [String]? = nil
    package var fileGroups: [FileGroupConfig]? = nil
    package var defaults: PullRequestDefaultsConfig? = nil
    package var reviewQueue: String? = nil

    package init(targets: [String]? = nil, template: String? = nil, staleDays: Int? = nil, hiddenFiles: [String]? = nil, fileGroups: [FileGroupConfig]? = nil, defaults: PullRequestDefaultsConfig? = nil, reviewQueue: String? = nil) {
        self.targets = targets
        self.template = template
        self.staleDays = staleDays
        self.hiddenFiles = hiddenFiles
        self.fileGroups = fileGroups
        self.defaults = defaults
        self.reviewQueue = reviewQueue
    }
}
