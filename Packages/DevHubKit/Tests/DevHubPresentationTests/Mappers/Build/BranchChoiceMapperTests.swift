import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct BranchChoiceMapperTests {
    @Test func localsComeFirstWithCheckoutDetail() {
        var checkedOut = GitBranchFixture.feature
        checkedOut.name = "feature/gifts"
        checkedOut.worktreePath = "/tmp/gifts"

        let choices = BranchChoiceMapper.choices(local: [GitBranchFixture.feature, checkedOut], remote: [], remoteName: "origin", query: "")

        #expect(choices == [
            BranchChoiceModel(name: "feature/login", detail: "local"),
            BranchChoiceModel(name: "feature/gifts", detail: "local · has a checkout")
        ])
    }

    @Test func remotesDropOriginAndSkipNamesThatExistLocally() {
        let remotes = [
            RemoteBranch(name: "origin/feature/login", author: "", subject: "", commitDate: nil),
            RemoteBranch(name: "origin/feature/gifts", author: "", subject: "", commitDate: nil)
        ]

        let choices = BranchChoiceMapper.choices(local: [GitBranchFixture.feature], remote: remotes, remoteName: "origin", query: "")

        #expect(choices == [
            BranchChoiceModel(name: "feature/login", detail: "local"),
            BranchChoiceModel(name: "feature/gifts", detail: "remote")
        ])
    }

    @Test func queryFiltersCaseInsensitivelyAfterTrimming() {
        let remotes = [RemoteBranch(name: "origin/feature/gifts", author: "", subject: "", commitDate: nil)]

        let choices = BranchChoiceMapper.choices(local: [GitBranchFixture.feature], remote: remotes, remoteName: "origin", query: "  GIFT \n")

        #expect(choices.map(\.name) == ["feature/gifts"])
    }

    @Test func resultIsLimitedToTwoHundred() {
        let remotes = (0..<250).map { RemoteBranch(name: "origin/branch-\($0)", author: "", subject: "", commitDate: nil) }

        let choices = BranchChoiceMapper.choices(local: [], remote: remotes, remoteName: "origin", query: "")

        #expect(BranchChoiceMapper.limit == 200)
        #expect(choices.count == 200)
        #expect(choices.last?.name == "branch-199")
    }

    @Test func idIsTheName() {
        #expect(BranchChoiceModel(name: "dev", detail: "local").id == "dev")
    }
}
