import DevHubDomain
import Testing

@Suite struct PipelineStatePolicyTests {
    @Test(arguments: [CheckStatus.running, .pending, .created, .waitingForResource, .preparing, .scheduled])
    func aStartedOrWaitingPipelineIsActive(status: CheckStatus) {
        #expect(PipelineStatePolicy.isActive(status))
    }

    @Test(arguments: [CheckStatus.success, .failed, .canceled, .skipped, .manual, .other("x")])
    func aFinishedPipelineIsNotActive(status: CheckStatus) {
        #expect(PipelineStatePolicy.isActive(status) == false)
    }
}
