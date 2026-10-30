import Testing
@testable import DevHubPresentation

@Suite struct SchemeEditorMapperTests {

    @Test func loadingShowsAMessageAndTheSpinner() {
        let model = SchemeEditorMapper.model(manual: [], suggestions: [], isLoaded: false, isLoading: true)

        #expect(model.isLoading)
        #expect(model.message != nil)
    }

    @Test func suggestionsHideTheMessage() {
        let model = SchemeEditorMapper.model(manual: ["Tools"], suggestions: ["Widget"], isLoaded: true, isLoading: false)

        #expect(model == SchemeEditorModel(manual: ["Tools"], suggestions: ["Widget"], message: nil, isLoading: false))
    }

    @Test func noSuggestionsAfterLoadingShowsAMessage() {
        let model = SchemeEditorMapper.model(manual: [], suggestions: [], isLoaded: true, isLoading: false)

        #expect(model.message != nil)
        #expect(model.isLoading == false)
    }

    @Test func nothingLoadedShowsNoMessage() {
        #expect(SchemeEditorMapper.model(manual: [], suggestions: [], isLoaded: false, isLoading: false).message == nil)
    }
}
