import Foundation
import DevHubDomain
import DevHubUI

enum PaletteCommand: Hashable {
    case showTab(TabID)
    case runAction(CatalogAction)
    case selectTarget(Simulator.ID)
    case buildAndRun(on: Simulator.ID)
    case switchBranch(String)
    case buildBranch(String)
    case createWorktree(String)
    case buildWorktree(Worktree.ID)
    case openFolder(String)
    case showPullRequest(Int)
    case resumeSession(command: String, folder: String, title: String)
    case openSettings
}
