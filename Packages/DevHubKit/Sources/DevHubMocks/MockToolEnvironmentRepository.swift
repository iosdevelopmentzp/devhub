import Foundation
import DevHubDomain

struct MockToolEnvironmentRepository: ToolEnvironmentRepository {

    func setDeveloperDir(_ path: String?) async {}
}
