import Foundation

package struct CIRedactionSubjects: Hashable, Sendable {
    package var organization: String? = nil
    package var repository: String? = nil
    package var host: String? = nil
    package var branches: [String] = []
    package var logins: [String] = []
    package var homeFolder: String? = nil

    package init(organization: String? = nil, repository: String? = nil, host: String? = nil, branches: [String] = [], logins: [String] = [], homeFolder: String? = nil) {
        self.organization = organization
        self.repository = repository
        self.host = host
        self.branches = branches
        self.logins = logins
        self.homeFolder = homeFolder
    }
}
