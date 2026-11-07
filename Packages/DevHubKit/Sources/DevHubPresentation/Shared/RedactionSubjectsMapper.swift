import Foundation
import DevHubDomain

enum RedactionSubjectsMapper {

    static func subjects(host: CodeHost?, currentBranch: String?, baseName: String, requests: [PullRequestSummary], username: String?, home: String) -> RedactionSubjects {
        let parts = host?.path.split(separator: "/").map(String.init) ?? []
        var branches = Set(requests.flatMap { [$0.sourceBranch, $0.targetBranch] })
        branches.insert(baseName)
        if let currentBranch {
            branches.insert(currentBranch)
        }
        var logins = Set(requests.flatMap { [$0.author] + $0.approvedBy + $0.assignees + $0.reviewers + $0.changesRequestedBy })
        if let username {
            logins.insert(username)
        }
        return RedactionSubjects(
            organization: parts.first,
            repository: parts.count > 1 ? parts.last : nil,
            host: host?.host,
            branches: branches.filter { $0.isEmpty == false }.sorted(),
            logins: logins.filter { $0.isEmpty == false }.sorted(),
            homeFolder: home
        )
    }

    static func adding(project: Project?, config: ProjectConfig, to subjects: RedactionSubjects) -> RedactionSubjects {
        var result = subjects
        if let home = subjects.homeFolder {
            let user = (home as NSString).lastPathComponent
            result.userName = user.isEmpty ? nil : user
        }
        if let project {
            result.projectFolder = project.path
            let folder = (project.path as NSString).lastPathComponent
            result.projectNames = meaningful([project.name, folder] + [config.name].compactMap { $0 })
        }
        let xcode = config.xcode
        let schemes = [project?.scheme, xcode?.scheme].compactMap { $0 } + (xcode?.schemes ?? [])
        let bundleIDs = [project?.bundleID, xcode?.bundleID].compactMap { $0 } + Array((xcode?.bundleIDs ?? [:]).values)
        result.schemes = meaningful(schemes)
        result.bundleIDs = meaningful(bundleIDs)
        return result
    }

    private static func meaningful(_ values: [String]) -> [String] {
        Array(Set(values.filter { $0.isEmpty == false })).sorted()
    }
}
