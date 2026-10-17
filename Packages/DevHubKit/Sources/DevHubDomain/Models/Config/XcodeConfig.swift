import Foundation

package struct XcodeConfig: Codable, Hashable, Sendable {
    package var container: String? = nil
    package var scheme: String? = nil
    package var configuration: String? = nil
    package var bundleID: String? = nil
    package var schemes: [String]? = nil
    package var bundleIDs: [String: String]? = nil

    package init(
        container: String? = nil,
        scheme: String? = nil,
        configuration: String? = nil,
        bundleID: String? = nil,
        schemes: [String]? = nil,
        bundleIDs: [String: String]? = nil
    ) {
        self.container = container
        self.scheme = scheme
        self.configuration = configuration
        self.bundleID = bundleID
        self.schemes = schemes
        self.bundleIDs = bundleIDs
    }
}
