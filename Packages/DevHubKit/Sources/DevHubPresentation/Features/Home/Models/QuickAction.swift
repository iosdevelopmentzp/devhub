import Foundation
import DevHubDomain
import DevHubUI

struct QuickAction: Identifiable, Hashable {
    enum Kind: Hashable {
        case buildAndRun
        case runAndAttach
        case openXcode
        case openFinder
        case openTerminal
        case copyBranch
        case openRepository
        case newMergeRequest
    }

    var id: Kind { kind }
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Tint
    var kind: Kind

    static let all: [QuickAction] = [
        QuickAction(title: "Build & Run", subtitle: "Target simulator, run bar options", systemImage: "play.fill", tint: .green, kind: .buildAndRun),
        QuickAction(title: "Run & Attach", subtitle: "Build, launch, attach Xcode", systemImage: "ladybug.fill", tint: .orange, kind: .runAndAttach),
        QuickAction(title: "Open in Xcode", subtitle: "Main checkout", systemImage: "hammer.fill", tint: .indigo, kind: .openXcode),
        QuickAction(title: "Open folder", subtitle: "Reveal in Finder", systemImage: "folder.fill", tint: .blue, kind: .openFinder),
        QuickAction(title: "Terminal here", subtitle: "Main checkout", systemImage: "terminal.fill", tint: .gray, kind: .openTerminal),
        QuickAction(title: "Copy branch", subtitle: "Current branch name", systemImage: "doc.on.doc.fill", tint: .teal, kind: .copyBranch),
        QuickAction(title: "Repository", subtitle: "Open on GitLab", systemImage: "globe", tint: .purple, kind: .openRepository),
        QuickAction(title: "Merge request", subtitle: "New MR for this branch", systemImage: "arrow.triangle.pull", tint: .pink, kind: .newMergeRequest)
    ]
}
