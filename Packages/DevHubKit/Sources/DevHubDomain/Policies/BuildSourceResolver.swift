import Foundation

package enum BuildSourceResolver {
    package struct BuildSourceResolution: Hashable, Sendable {
        package let path: String
        package let worktreeID: Worktree.ID?
        package let label: String

        package init(path: String, worktreeID: Worktree.ID?, label: String) {
            self.path = path
            self.worktreeID = worktreeID
            self.label = label
        }
    }

    package static func checkoutPath(forBranch name: String, in worktrees: [Worktree], remote: String) -> String? {
        let local = BranchName(name, remote: remote).local
        return worktrees.first { $0.branch == local && $0.isMissing == false }?.path
    }

    package static func resolve(
        source: BuildSourceChoice,
        worktrees: [Worktree],
        mainCheckoutPath: String,
        projectName: String,
        remote: String
    ) -> BuildSourceResolution {
        switch source {
        case .main:
            let name = worktrees.first(where: \.isMain)?.displayName ?? projectName
            return BuildSourceResolution(path: mainCheckoutPath, worktreeID: nil, label: "\(name) · main checkout")
        case .worktree(let path):
            let isAvailable = worktrees.contains { $0.path == path && $0.isMissing == false }
            return BuildSourceResolution(
                path: isAvailable ? path : mainCheckoutPath,
                worktreeID: path,
                label: worktrees.first { $0.path == path }?.displayName ?? (path as NSString).lastPathComponent
            )
        case .branch(let name):
            let checkout = checkoutPath(forBranch: name, in: worktrees, remote: remote)
            let linkedCheckout = checkout.flatMap { path in
                worktrees.first { $0.path == path }?.isMain == false ? path : nil
            }
            return BuildSourceResolution(
                path: checkout ?? mainCheckoutPath,
                worktreeID: linkedCheckout,
                label: checkout == nil ? "\(name) · new worktree on run" : name
            )
        }
    }
}
