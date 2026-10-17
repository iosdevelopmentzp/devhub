import Foundation
import DevHubDomain

struct MockProjectDetector: ProjectDetecting {

    func project(at folder: URL) -> Project {
        let path = folder.path.abbreviatingHome
        return Project(
            id: path,
            name: folder.lastPathComponent,
            path: path,
            scheme: folder.lastPathComponent,
            bundleID: "",
            identity: nil
        )
    }

    func isGitRepository(_ folder: URL) -> Bool {
        true
    }
}
