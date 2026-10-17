import Testing
@testable import DevHubDomain

@Suite struct GitFileChangeTests {
    private let change = GitFileChange(path: "Sources/App/Login.swift", originalPath: nil, area: .staged, kind: .modified)

    @Test func idCombinesAreaAndPath() {
        #expect(change.id == "1:Sources/App/Login.swift")
    }

    @Test func sameFileInTwoAreasHasTwoIDs() {
        let unstaged = GitFileChange(path: change.path, originalPath: nil, area: .unstaged, kind: .modified)

        #expect(unstaged.id == "2:Sources/App/Login.swift")
        #expect(unstaged.id != change.id)
    }

    @Test func fileNameIsTheLastComponent() {
        #expect(change.fileName == "Login.swift")
    }

    @Test func folderIsThePathWithoutTheFile() {
        #expect(change.folder == "Sources/App")
    }

    @Test func fileAtTheRootHasAnEmptyFolder() {
        let root = GitFileChange(path: "README.md", originalPath: nil, area: .untracked, kind: .untracked)

        #expect(root.folder == "")
        #expect(root.fileName == "README.md")
    }
}
