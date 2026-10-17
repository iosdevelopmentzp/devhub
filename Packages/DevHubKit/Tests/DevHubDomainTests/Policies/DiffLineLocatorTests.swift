import Testing
@testable import DevHubDomain

@Suite struct DiffLineLocatorTests {
    private let lines = [
        "@@ -10,4 +10,5 @@ final class A {",
        "     let a = 1",
        "-    let b = 2",
        "+    let b = 3",
        "+    let c = 4",
        "     let d = 5",
        "@@ -40,2 +41,2 @@",
        "     func f() {}",
        "-    func g() {}",
        "\\ No newline at end of file",
        "+    func h() {}",
    ]

    @Test(arguments: [
        (10, false, 1),
        (11, false, 3),
        (12, false, 4),
        (13, false, 5),
        (41, false, 7),
        (42, false, 10),
        (11, true, 2),
        (12, true, 5),
        (41, true, 8),
    ])
    func findsTheLine(line: Int, isOld: Bool, index: Int) {
        #expect(DiffLineLocator.index(ofLine: line, isOld: isOld, in: lines) == index)
    }

    @Test func aLineOutsideTheHunksIsNotFound() {
        #expect(DiffLineLocator.index(ofLine: 30, isOld: false, in: lines) == nil)
        #expect(DiffLineLocator.index(ofLine: 1, isOld: false, in: []) == nil)
    }
}
