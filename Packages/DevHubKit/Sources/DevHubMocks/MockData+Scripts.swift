import Foundation
import DevHubDomain

extension MockData {
    package static let scripts: [ScriptAction] = [
        ScriptAction(
            id: "clean-derived",
            title: "Clean DerivedData",
            subtitle: "Removes ~/Library/Developer/Xcode/DerivedData for this project",
            fileName: "clean-derived-data.sh",
            systemImage: "trash",
            lastRun: ago(days: 1)
        ),
        ScriptAction(
            id: "swiftgen",
            title: "Regenerate SwiftGen",
            subtitle: "Runs swiftgen.yml after asset or string changes",
            fileName: "swiftgen.sh",
            systemImage: "wand.and.stars",
            lastRun: ago(hours: 5)
        ),
        ScriptAction(
            id: "rebase-dev",
            title: "Rebase onto dev",
            subtitle: "Fetches origin and rebases the current branch",
            fileName: "rebase-dev.sh",
            systemImage: "arrow.triangle.merge",
            lastRun: ago(hours: 2)
        ),
        ScriptAction(
            id: "open-mr",
            title: "Open MR in GitLab",
            subtitle: "Opens the merge request for the current branch",
            fileName: "open-mr.sh",
            systemImage: "safari",
            lastRun: nil
        ),
        ScriptAction(
            id: "periphery",
            title: "Dead code scan",
            subtitle: "Runs Periphery with .periphery.yml",
            fileName: "periphery.sh",
            systemImage: "magnifyingglass",
            lastRun: ago(days: 4)
        )
    ]
}
