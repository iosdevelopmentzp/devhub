import Foundation

package enum FlakyTrackingPolicy {
    package static let limit = 500

    package static func flakes(new record: CIWorkflowRecord, earlier: [CIWorkflowRecord]) -> [CIFlakyTest] {
        guard let run = record.workflow.runID else { return [] }
        let stillFailing = Set(record.failedTests.values.flatMap { $0 }.map(key))
        var found: [String: CIFlakyTest] = [:]
        for old in earlier where old.id != record.id && old.workflow.runID == run {
            for (jobID, tests) in old.failedTests {
                guard let job = old.workflow.jobs.first(where: { $0.id == jobID }), passes(job.name, in: record.workflow) else { continue }
                for test in tests where stillFailing.contains(key(test)) == false {
                    found[key(test)] = CIFlakyTest(className: test.className, name: test.name, jobName: job.name, workflowName: old.workflow.name, timesFlaked: 1, source: .devhub)
                }
            }
        }
        return found.values.sorted { key($0) < key($1) }
    }

    package static func add(_ flakes: [CIFlakyTest], to records: [FlakyTestRecord], at date: Date) -> [FlakyTestRecord] {
        var kept = records
        for flake in flakes {
            if let index = kept.firstIndex(where: { $0.className == flake.className && $0.name == flake.name }) {
                let old = kept[index]
                kept[index] = FlakyTestRecord(className: old.className, name: old.name, jobName: flake.jobName ?? old.jobName, workflowName: flake.workflowName ?? old.workflowName, timesFlaked: old.timesFlaked + flake.timesFlaked, lastFlakedAt: date)
            } else {
                kept.append(FlakyTestRecord(className: flake.className, name: flake.name, jobName: flake.jobName, workflowName: flake.workflowName, timesFlaked: flake.timesFlaked, lastFlakedAt: date))
            }
        }
        return Array(kept.sorted { $0.lastFlakedAt > $1.lastFlakedAt }.prefix(limit))
    }

    package static func tests(_ records: [FlakyTestRecord]) -> [CIFlakyTest] {
        records.map { CIFlakyTest(className: $0.className, name: $0.name, jobName: $0.jobName, workflowName: $0.workflowName, timesFlaked: $0.timesFlaked, source: .devhub) }
    }

    package static func merged(insights: [CIFlakyTest], ledger: [CIFlakyTest]) -> [CIFlakyTest] {
        var best: [String: CIFlakyTest] = [:]
        for test in insights + ledger {
            let id = key(test)
            if let current = best[id], current.timesFlaked >= test.timesFlaked { continue }
            best[id] = test
        }
        return best.values.sorted { key($0) < key($1) }
    }

    private static func passes(_ jobName: String, in workflow: CIWorkflow) -> Bool {
        workflow.status == .success || workflow.jobs.contains { $0.name == jobName && $0.status == .success }
    }

    private static func key(_ test: CITestResult) -> String {
        "\(test.className).\(test.name)"
    }

    private static func key(_ test: CIFlakyTest) -> String {
        "\(test.className).\(test.name)"
    }
}
