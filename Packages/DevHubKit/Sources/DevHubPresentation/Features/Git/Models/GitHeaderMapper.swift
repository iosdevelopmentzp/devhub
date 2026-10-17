import Foundation
import DevHubDomain
import DevHubUI

enum GitHeaderMapper {

    static func model(for snapshot: GitSnapshot, baseName: String, ticket: TicketSettings) -> GitHeaderModel {
        let branch = snapshot.branch ?? ""
        return GitHeaderModel(
            branchTitle: snapshot.branch ?? "detached HEAD",
            branchCopyValue: snapshot.branch ?? snapshot.head,
            head: snapshot.head,
            statusTag: statusTag(snapshot),
            upstreamTag: snapshot.upstream.map { TagModel($0, systemImage: "icloud") },
            tags: syncTags(snapshot, baseName: baseName),
            stashTag: stashTag(snapshot),
            ticket: snapshot.branch.flatMap { TicketMapper.model(for: [$0], ticket: ticket) },
            showsMergeRequestLine: snapshot.webURL != nil && snapshot.branch != nil,
            operationText: snapshot.operation.map { "\($0.capitalized) in progress. Resolve conflicts in the terminal or Xcode, then continue." },
            canContinueOperation: snapshot.operation == "rebase",
            actions: actions(snapshot, baseName: baseName),
            webBranch: snapshot.webURL == nil ? nil : snapshot.branch,
            newMergeRequestHint: "New merge request for \(branch): title, description and labels here, pushes first when needed",
            branchOnWebHint: "Open \(branch) on GitLab",
            forcePushMessage: "Force push \(branch)? The remote branch is replaced with your local one. --force-with-lease refuses when someone else pushed meanwhile.",
            rebaseMessage: "Rebase \(branch) on \(snapshot.baseBranch)? \(snapshot.behindBase) new commits come in. Local changes are stashed and restored. After that you need a force push."
        )
    }

    static func checkoutLabel(path: String, worktree: Worktree?) -> String {
        guard let worktree else { return path.abbreviatingHome }
        return worktree.isMain ? "Main checkout" : "Worktree \(worktree.displayName)"
    }

    static func checkoutTitle(_ worktree: Worktree) -> String {
        worktree.isMain ? "\(worktree.displayName) · main checkout" : worktree.displayName
    }

    static func fetchedText(_ date: Date) -> String {
        "fetched \(date.relativeDescription)"
    }

    private static func statusTag(_ snapshot: GitSnapshot) -> TagModel {
        guard snapshot.changedFiles > 0 else {
            return TagModel("clean", tint: .green, systemImage: "checkmark", hint: "No uncommitted changes")
        }
        return TagModel(
            "\(snapshot.changedFiles) changed",
            tint: .orange,
            systemImage: "pencil",
            hint: "\(snapshot.changedFiles) files with changes that are not committed"
        )
    }

    private static func syncTags(_ snapshot: GitSnapshot, baseName: String) -> [TagModel] {
        var tags: [TagModel] = []
        if let upstream = snapshot.upstream {
            if snapshot.ahead > 0 {
                tags.append(
                    TagModel(
                        "\(SyncText.ahead(snapshot.ahead)) to push",
                        tint: .blue,
                        hint: "\(snapshot.ahead) local commits are not on \(upstream) yet"
                    )
                )
            }
            if snapshot.behind > 0 {
                tags.append(
                    TagModel(
                        "\(SyncText.behind(snapshot.behind)) to pull",
                        tint: .orange,
                        hint: "\(upstream) has \(snapshot.behind) commits you do not have. Pull brings them in."
                    )
                )
            }
        } else if snapshot.branch != nil {
            tags.append(TagModel("not pushed", tint: .orange, systemImage: "icloud.slash", hint: "The branch has no remote branch yet. Push creates it."))
        }
        if snapshot.behindBase > 0 {
            tags.append(
                TagModel(
                    "\(snapshot.behindBase) behind \(snapshot.baseBranch)",
                    tint: .purple,
                    hint: "\(snapshot.baseBranch) has \(snapshot.behindBase) commits this branch does not have. Rebase on \(baseName) brings them in."
                )
            )
        }
        if snapshot.aheadOfBase > 0 {
            tags.append(
                TagModel(
                    "\(snapshot.aheadOfBase) ahead of \(snapshot.baseBranch)",
                    tint: .teal,
                    hint: "\(snapshot.aheadOfBase) commits of this branch are not in \(snapshot.baseBranch)"
                )
            )
        }
        return tags
    }

    private static func stashTag(_ snapshot: GitSnapshot) -> TagModel? {
        guard snapshot.stashCount > 0 else { return nil }
        return TagModel(
            "\(snapshot.stashCount) stashed",
            systemImage: "tray.full",
            hint: "\(snapshot.stashCount) entries in git stash, shared by all worktrees. Click to see them."
        )
    }

    private static func actions(_ snapshot: GitSnapshot, baseName: String) -> [GitHeaderActionModel] {
        let hasBranch = snapshot.branch != nil
        var items = [
            GitHeaderActionModel(
                id: .fetch,
                title: "Fetch",
                systemImage: "arrow.down.circle",
                hint: "Download new commits and branches from the remote. git fetch --prune <remote>",
                priority: 3,
                isDisabled: false
            ),
            GitHeaderActionModel(
                id: .pull,
                title: "Pull",
                systemImage: "arrow.down",
                hint: "Fast-forward this branch from its remote. git pull --ff-only",
                priority: 5,
                isDisabled: snapshot.upstream == nil
            ),
            GitHeaderActionModel(
                id: .push,
                title: "Push",
                systemImage: "arrow.up",
                hint: snapshot.upstream == nil ? "Publish this branch. git push -u <remote> <branch>" : "Send your commits. git push",
                priority: 6,
                isDisabled: hasBranch == false
            ),
            GitHeaderActionModel(
                id: .forcePush,
                title: "Force Push…",
                systemImage: "arrow.up.square",
                hint: "Replace the remote branch with yours. Asks first. git push --force-with-lease",
                priority: 2,
                isDisabled: hasBranch == false
            ),
            GitHeaderActionModel(
                id: .rebase,
                title: "Rebase on \(baseName)…",
                systemImage: "arrow.triangle.merge",
                hint: "Fetch \(baseName) and replay your commits on top of it. Asks first. git rebase --autostash \(snapshot.baseBranch)",
                priority: 4,
                isDisabled: hasBranch == false || snapshot.operation != nil
            ),
            GitHeaderActionModel(
                id: .updateBase,
                title: "Update \(baseName)",
                systemImage: "arrow.down.to.line",
                hint: "Fast-forward the local \(baseName) branch without switching to it",
                priority: 1,
                isDisabled: false
            )
        ]
        if snapshot.changedFiles > 0 {
            items.append(
                GitHeaderActionModel(
                    id: .stash,
                    title: "Stash…",
                    systemImage: "tray.and.arrow.down",
                    hint: "Put away all local changes, untracked files too, with an optional message. git stash push --include-untracked",
                    priority: 0,
                    isDisabled: false
                )
            )
        } else if snapshot.stashCount > 0 {
            items.append(
                GitHeaderActionModel(
                    id: .popStash,
                    title: "Pop Stash",
                    systemImage: "tray.and.arrow.up",
                    hint: "Bring back the newest stash. git stash pop",
                    priority: 0,
                    isDisabled: false
                )
            )
        }
        return items
    }
}
