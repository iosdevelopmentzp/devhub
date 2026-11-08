import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct NetworkEmptyStateMapperTests {

    @Test func withoutRequestsTheFirstMissingStepIsShown() {
        #expect(map(hasBaseURLVariable: false)?.title == "Network mocks are off for this project")
        #expect(map(hasBootedSimulator: false)?.title == "No simulator booted")
        #expect(map(isIntercepting: false)?.title == "Mock server is off")
        #expect(map()?.title == "Waiting for requests…")
    }

    @Test func aSourceScriptIsEnoughWithoutTheMockServer() {
        let model = map(hasBaseURLVariable: false, hasSourceScript: true, isIntercepting: false)

        #expect(model?.title == "Waiting for requests…")
        #expect(model?.description.contains("network.sourceScript") == true)
        #expect(map(hasSourceScript: true, hasBootedSimulator: false)?.title == "No simulator booted")
    }

    @Test func aFilterWithNoMatchesSaysSo() {
        let model = map(hasRequests: true, shownIsEmpty: true, filter: .failed)

        #expect(model == NetworkEmptyStateModel(title: "No failed requests", systemImage: "line.3.horizontal.decrease.circle", description: "Choose All to see every request."))
    }

    @Test func requestsOrASearchShowNoMessage() {
        #expect(map(hasRequests: true, shownIsEmpty: false, filter: .failed) == nil)
        #expect(map(hasRequests: true, shownIsEmpty: true, isSearching: true, filter: .failed) == nil)
        #expect(map(hasRequests: true, shownIsEmpty: true, filter: .all) == nil)
    }

    private func map(
        hasBaseURLVariable: Bool = true,
        hasSourceScript: Bool = false,
        hasBootedSimulator: Bool = true,
        isIntercepting: Bool = true,
        hasRequests: Bool = false,
        shownIsEmpty: Bool = true,
        isSearching: Bool = false,
        filter: NetworkRequestFilter = .all
    ) -> NetworkEmptyStateModel? {
        NetworkEmptyStateMapper.model(
            hasBaseURLVariable: hasBaseURLVariable,
            hasSourceScript: hasSourceScript,
            hasBootedSimulator: hasBootedSimulator,
            isIntercepting: isIntercepting,
            hasRequests: hasRequests,
            shownIsEmpty: shownIsEmpty,
            isSearching: isSearching,
            filter: filter
        )
    }
}
