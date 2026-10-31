import Foundation

package enum FlakyTestPolicy {

    package static func timesFlaked(_ test: CITestResult, in flaky: [CIFlakyTest]) -> Int? {
        let matches = flaky.filter { $0.className == test.className && $0.name == test.name }
        guard matches.isEmpty == false else { return nil }
        return matches.map(\.timesFlaked).max()
    }

    package static func isFlaky(_ test: CITestResult, in flaky: [CIFlakyTest]) -> Bool {
        timesFlaked(test, in: flaky) != nil
    }

    package static func flakyCount(of tests: [CITestResult], in flaky: [CIFlakyTest]) -> Int {
        tests.filter { isFlaky($0, in: flaky) }.count
    }
}
