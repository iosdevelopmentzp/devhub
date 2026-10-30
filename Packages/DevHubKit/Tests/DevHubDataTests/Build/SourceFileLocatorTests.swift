import Foundation
import DevHubTestSupport
import Testing
@testable import DevHubData

@Suite struct SourceFileLocatorTests {
    @Test func findsASwiftFileByNameAnywhereInTheCheckout() throws {
        let directory = try TemporaryDirectory()
        let file = try directory.write("", to: "Tests/Login/LoginTests.swift")
        _ = try directory.write("", to: "Sources/Login.swift")

        let locator = SourceFileLocator(root: directory.url.path)

        #expect(locator.path(forFileName: "LoginTests.swift").map(resolved) == resolved(file.path))
        #expect(locator.path(forFileName: "Missing.swift") == nil)
    }

    @Test func skipsHiddenBuildAndDependencyFolders() throws {
        let directory = try TemporaryDirectory()
        _ = try directory.write("", to: ".build/checkouts/Dep/Hidden.swift")
        _ = try directory.write("", to: "Pods/Alamofire/Pod.swift")
        _ = try directory.write("", to: "DerivedData/Derived.swift")
        _ = try directory.write("", to: "notes.txt")

        let locator = SourceFileLocator(root: directory.url.path)

        #expect(locator.path(forFileName: "Hidden.swift") == nil)
        #expect(locator.path(forFileName: "Pod.swift") == nil)
        #expect(locator.path(forFileName: "Derived.swift") == nil)
        #expect(locator.path(forFileName: "notes.txt") == nil)
    }
}

private func resolved(_ path: String) -> String {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().path
}
