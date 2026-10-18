import Testing
@testable import DevHubDomain

@Suite struct AppLogPredicatePolicyTests {
    @Test func theSubsystemWinsOverTheProcess() {
        #expect(AppLogPredicatePolicy.predicate(for: AppLogFilter(process: "App", subsystem: " com.example.app ")) == #"subsystem == "com.example.app""#)
        #expect(AppLogPredicatePolicy.predicate(for: AppLogFilter(process: " App ", subsystem: "")) == #"process == "App""#)
        #expect(AppLogPredicatePolicy.predicate(for: AppLogFilter(process: " ", subsystem: "")) == nil)
    }

    @Test func quotesAreEscaped() {
        #expect(AppLogPredicatePolicy.predicate(for: AppLogFilter(process: #"My "App""#, subsystem: "")) == #"process == "My \"App\"""#)
    }

    @Test func anEmptyFilterIsEmpty() {
        #expect(AppLogFilter(process: " ", subsystem: "\n").isEmpty)
        #expect(AppLogFilter(process: "", subsystem: "sub").isEmpty == false)
    }
}
