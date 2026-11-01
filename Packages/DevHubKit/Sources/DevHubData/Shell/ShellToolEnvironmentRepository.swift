import Foundation
import DevHubDomain

struct ShellToolEnvironmentRepository: ToolEnvironmentRepository {
    let state: DeveloperDirState

    func setDeveloperDir(_ path: String?) async {
        state.set(path)
    }
}
