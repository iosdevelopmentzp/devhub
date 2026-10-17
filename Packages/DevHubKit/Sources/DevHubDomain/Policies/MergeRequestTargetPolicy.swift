import Foundation

package enum MergeRequestTargetPolicy {
    private static let preferred = ["dev", "develop", "main", "master"]

    package static func targets(remoteBranches: [String], source: String, baseName: String) -> [String] {
        let sourceName = BranchName(source).local
        let names = Set(remoteBranches.map { BranchName($0).local }).subtracting([sourceName, "HEAD"])
        var leading: [String] = []
        for name in [preferred[0], baseName] + preferred.dropFirst() where names.contains(name) && leading.contains(name) == false {
            leading.append(name)
        }
        guard names.isEmpty == false else { return sourceName == baseName ? [] : [baseName] }
        return leading + names.subtracting(leading).sorted()
    }
}
