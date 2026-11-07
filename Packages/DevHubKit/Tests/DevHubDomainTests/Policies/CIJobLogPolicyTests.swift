import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIJobLogPolicyTests {
    @Test func failedStepsComeFirstWithTheirExitCode() {
        let steps = [
            CIJobLogStep(name: "Spin up environment", exitCode: 0, output: "ready"),
            CIJobLogStep(name: "Run tests", exitCode: 65, output: "failed\n"),
        ]

        #expect(CIJobLogPolicy.text(steps: steps) == "== Run tests (exit 65)\nfailed\n\n== Spin up environment\nready")
    }

    @Test func aFailedStepKeeps200LinesAndAnotherStep20() {
        let long = (1...230).map(String.init).joined(separator: "\n")

        let failed = CIJobLogPolicy.text(steps: [CIJobLogStep(name: "Run", exitCode: 1, output: long)]).split(separator: "\n")
        let other = CIJobLogPolicy.text(steps: [CIJobLogStep(name: "Checkout", exitCode: 0, output: long)]).split(separator: "\n")

        #expect(failed.count == CIJobLogPolicy.failedStepLineLimit + 2)
        #expect(failed[1] == "… 30 more lines above")
        #expect(failed[2] == "31")
        #expect(failed.last == "230")
        #expect(other.count == CIJobLogPolicy.otherStepLineLimit + 2)
        #expect(other[1] == "… 210 more lines above")
        #expect(other[2] == "211")
    }

    @Test func oneDroppedLineIsSingular() {
        let text = CIJobLogPolicy.text(steps: [CIJobLogStep(name: "Checkout", exitCode: 0, output: (1...21).map(String.init).joined(separator: "\n"))])

        #expect(text.split(separator: "\n")[1] == "… 1 more line above")
    }

    @Test func anEmptyStepKeepsOnlyItsHeaderAndBlankEdgesAreTrimmed() {
        #expect(CIJobLogPolicy.text(steps: [CIJobLogStep(name: "Save cache", exitCode: 0, output: "\n  \n")]) == "== Save cache")
        #expect(CIJobLogPolicy.text(steps: [CIJobLogStep(name: "Run", exitCode: nil, output: "\nline\n\n")]) == "== Run\nline")
        #expect(CIJobLogPolicy.text(steps: []) == "")
    }
}
