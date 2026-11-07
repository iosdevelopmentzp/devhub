import Foundation

package enum FlakyTestPolicy {

    package static func timesFlaked(_ test: CITestResult, in flaky: [CIFlakyTest]) -> Int? {
        match(test, in: flaky)?.timesFlaked
    }

    package static func match(_ test: CITestResult, in flaky: [CIFlakyTest]) -> CIFlakyTest? {
        flaky.filter { $0.className == test.className && $0.name == test.name }.max { $0.timesFlaked < $1.timesFlaked }
    }

    package static func isFlaky(_ test: CITestResult, in flaky: [CIFlakyTest]) -> Bool {
        timesFlaked(test, in: flaky) != nil
    }

    package static func flakyCount(of tests: [CITestResult], in flaky: [CIFlakyTest]) -> Int {
        tests.filter { isFlaky($0, in: flaky) }.count
    }
}
