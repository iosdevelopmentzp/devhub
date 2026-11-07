import Foundation

package struct RedactionSubjects: Hashable, Sendable {
    package var organization: String? = nil
    package var repository: String? = nil
    package var host: String? = nil
    package var branches: [String] = []
    package var logins: [String] = []
    package var homeFolder: String? = nil
    package var userName: String? = nil
    package var projectFolder: String? = nil
    package var projectNames: [String] = []
    package var schemes: [String] = []
    package var bundleIDs: [String] = []

    package init(
        organization: String? = nil,
        repository: String? = nil,
        host: String? = nil,
        branches: [String] = [],
        logins: [String] = [],
        homeFolder: String? = nil,
        userName: String? = nil,
        projectFolder: String? = nil,
        projectNames: [String] = [],
        schemes: [String] = [],
        bundleIDs: [String] = []
    ) {
        self.organization = organization
        self.repository = repository
        self.host = host
        self.branches = branches
        self.logins = logins
        self.homeFolder = homeFolder
        self.userName = userName
        self.projectFolder = projectFolder
        self.projectNames = projectNames
        self.schemes = schemes
        self.bundleIDs = bundleIDs
    }
}
