import Foundation
import DevHubDomain
import DevHubUI

enum FileChangeGroupMapper {

    static func groups(for changes: [GitFileChange], isVisible: (GitFileChange) -> Bool, isBusy: Bool) -> [FileChangeGroupModel] {
        let hasUnstaged = changes.contains { $0.area == .unstaged }
        return GitFileChange.Area.allCases.compactMap { area in
            let visible = changes.filter { $0.area == area && isVisible($0) }
            guard visible.isEmpty == false else { return nil }
            return FileChangeGroupModel(
                id: area,
                title: "\(title(area)) \(visible.count)",
                action: action(area, hasUnstaged: hasUnstaged),
                isActionEnabled: isBusy == false,
                changes: visible
            )
        }
    }

    private static func title(_ area: GitFileChange.Area) -> String {
        switch area {
        case .conflicted: "Conflicts"
        case .staged: "Staged"
        case .unstaged: "Changes"
        case .untracked: "New files"
        }
    }

    private static func action(_ area: GitFileChange.Area, hasUnstaged: Bool) -> GroupAction? {
        switch area {
        case .conflicted: nil
        case .staged: GroupAction(title: "Unstage All", kind: .unstageAll)
        case .unstaged: GroupAction(title: "Stage All", kind: .stageAll)
        case .untracked: hasUnstaged ? nil : GroupAction(title: "Stage All", kind: .stageAll)
        }
    }
}
