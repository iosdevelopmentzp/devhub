import DevHubDomain
import Testing

@Suite struct PipelineStatePolicyTests {
    @Test(arguments: [PipelineStatus.running, .pending, .created, .waitingForResource, .preparing, .scheduled])
    func aStartedOrWaitingPipelineIsActive(status: PipelineStatus) {
        #expect(PipelineStatePolicy.isActive(status))
    }

    @Test(arguments: [PipelineStatus.success, .failed, .canceled, .skipped, .manual, .other("x")])
    func aFinishedPipelineIsNotActive(status: PipelineStatus) {
        #expect(PipelineStatePolicy.isActive(status) == false)
    }
}
