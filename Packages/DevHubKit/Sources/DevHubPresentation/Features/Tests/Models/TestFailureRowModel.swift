import Foundation

struct TestFailureRowModel: Identifiable, Equatable {
    let id: Int
    var test: String?
    var location: String?
    var message: String
    var path: String?
    var line: Int?
    var hint: String

    static let preview = TestFailureRowModel(
        id: 0,
        test: "LoginTests.testLoginWithWrongPassword",
        location: "LoginTests.swift:42",
        message: "XCTAssertEqual failed: (\"locked\") is not equal to (\"wrongPassword\")",
        path: "/Users/dev/Projects/ExampleApp/Tests/LoginTests.swift",
        line: 42,
        hint: "Open /Users/dev/Projects/ExampleApp/Tests/LoginTests.swift at line 42"
    )
}
