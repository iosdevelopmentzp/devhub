import Foundation
import Testing
@testable import DevHubData

@Suite struct LogCounterTests {
    @Test func countsFromOne() {
        let counter = LogCounter()

        let values: [Int] = [counter.next(), counter.next(), counter.next()]

        #expect(values == [1, 2, 3])
    }

    @Test func givesUniqueValuesAcrossThreads() async {
        let counter = LogCounter()

        let values = await withTaskGroup(of: Int.self) { group in
            for _ in 0..<500 {
                group.addTask { counter.next() }
            }
            var collected: [Int] = []
            for await value in group {
                collected.append(value)
            }
            return collected
        }

        #expect(Set(values) == Set(1...500))
    }
}
