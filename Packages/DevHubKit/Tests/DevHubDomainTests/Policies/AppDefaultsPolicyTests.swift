import Foundation
import Testing
@testable import DevHubDomain

@Suite struct AppDefaultsPolicyTests {
    private let suite = AppDefaultsSuite(
        name: "com.example.app",
        plistPath: "/data/Library/Preferences/com.example.app.plist",
        entries: [
            AppDefault(key: "apiEnvironment", kind: .string, text: "staging"),
            AppDefault(key: "onboardingDone", kind: .bool, text: "true"),
        ]
    )

    @Test func onlyStringsNumbersAndBooleansAreEditable() {
        #expect(AppDefaultsPolicy.editableKinds == [.string, .integer, .float, .bool])
        #expect(AppDefaultsPolicy.isEditable(.integer))
        #expect(AppDefaultsPolicy.isEditable(.dictionary) == false)
        #expect(AppDefaultsPolicy.isEditable(.data) == false)
    }

    @Test func valueParsesTheTextForEachKind() {
        #expect(AppDefaultsPolicy.value(kind: .string, text: " two words ") == .string(" two words "))
        #expect(AppDefaultsPolicy.value(kind: .integer, text: " 42 ") == .integer(42))
        #expect(AppDefaultsPolicy.value(kind: .float, text: "1.5") == .float(1.5))
        #expect(AppDefaultsPolicy.value(kind: .bool, text: "YES") == .bool(true))
        #expect(AppDefaultsPolicy.value(kind: .bool, text: "0") == .bool(false))
    }

    @Test func valueRejectsTextThatDoesNotFitTheKind() {
        #expect(AppDefaultsPolicy.value(kind: .integer, text: "4.2") == nil)
        #expect(AppDefaultsPolicy.value(kind: .float, text: "fast") == nil)
        #expect(AppDefaultsPolicy.value(kind: .bool, text: "maybe") == nil)
        #expect(AppDefaultsPolicy.value(kind: .array, text: "[1]") == nil)
    }

    @Test func toggledFlipsABoolean() {
        #expect(AppDefaultsPolicy.toggled(AppDefault(key: "a", kind: .bool, text: "true")) == .bool(false))
        #expect(AppDefaultsPolicy.toggled(AppDefault(key: "a", kind: .bool, text: "false")) == .bool(true))
        #expect(AppDefaultsPolicy.toggled(AppDefault(key: "a", kind: .string, text: "true")) == nil)
    }

    @Test func aNewKeyMustBeNonEmptyAndNew() {
        #expect(AppDefaultsPolicy.isValidKey("launchCount", in: suite))
        #expect(AppDefaultsPolicy.isValidKey("  ", in: suite) == false)
        #expect(AppDefaultsPolicy.isValidKey(" apiEnvironment ", in: suite) == false)
    }

    @Test func matchesTheKeyOrTheValueIgnoringCase() {
        let entry = AppDefault(key: "apiEnvironment", kind: .string, text: "Staging")

        #expect(AppDefaultsPolicy.matches(entry, query: ""))
        #expect(AppDefaultsPolicy.matches(entry, query: "API"))
        #expect(AppDefaultsPolicy.matches(entry, query: "stag"))
        #expect(AppDefaultsPolicy.matches(entry, query: "token") == false)
    }
}
