import Foundation

package struct StarterConfigFacts: Hashable, Sendable {
    package let name: String
    package let scheme: String
    package let bundleID: String
    package let remote: String
    package let hostKind: CodeHostKind?
    package let baseBranch: String?

    package init(name: String, scheme: String, bundleID: String, remote: String, hostKind: CodeHostKind?, baseBranch: String?) {
        self.name = name
        self.scheme = scheme
        self.bundleID = bundleID
        self.remote = remote
        self.hostKind = hostKind
        self.baseBranch = baseBranch
    }
}
