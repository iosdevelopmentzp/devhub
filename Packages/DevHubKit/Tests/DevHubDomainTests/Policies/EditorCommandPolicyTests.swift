import Foundation
import Testing
@testable import DevHubDomain

@Suite struct EditorCommandPolicyTests {
    @Test func everyEditorOpensTheLine() {
        #expect(EditorCommandPolicy.openFile("/a.swift", line: 12, editor: "Xcode") == .init(executable: "xed", arguments: ["--line", "12", "/a.swift"]))
        #expect(EditorCommandPolicy.openFile("/a.swift", line: 12, editor: "VS Code") == .init(executable: "code", arguments: ["--goto", "/a.swift:12"]))
        #expect(EditorCommandPolicy.openFile("/a.swift", line: 12, editor: "Cursor") == .init(executable: "cursor", arguments: ["--goto", "/a.swift:12"]))
        #expect(EditorCommandPolicy.openFile("/a.swift", line: 12, editor: "Zed") == .init(executable: "zed", arguments: ["/a.swift:12"]))
    }

    @Test func withoutALineOnlyThePathIsPassed() {
        #expect(EditorCommandPolicy.openFile("/a.swift", line: nil, editor: "Xcode").arguments == ["/a.swift"])
        #expect(EditorCommandPolicy.openFile("/a.swift", line: nil, editor: "VS Code").arguments == ["--goto", "/a.swift"])
    }

    @Test func anotherEditorOpensTheAppByName() {
        #expect(EditorCommandPolicy.openFile("/a.swift", line: 3, editor: "Nova") == .init(executable: "open", arguments: ["-a", "Nova", "/a.swift"]))
        #expect(EditorCommandPolicy.fallback("/a.swift", editor: "VS Code") == .init(executable: "open", arguments: ["-a", "Visual Studio Code", "/a.swift"]))
    }
}
