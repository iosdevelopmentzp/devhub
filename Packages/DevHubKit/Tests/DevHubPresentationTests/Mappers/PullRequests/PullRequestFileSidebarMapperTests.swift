import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestFileSidebarMapperTests {
    private var loaded: PullRequestDetailsModel.Loaded {
        guard case .loaded(let loaded) = PullRequestDetailsModel.preview.content else { fatalError("preview is loaded") }
        return loaded
    }

    @Test func theSidebarListsTheFilesWithTheirProgressAndGroups() {
        let viewed = PullRequestFileRowModel(id: "b.swift", letter: "A", letterTint: .green, letterHint: "Added", fileName: "b.swift", detail: "App", path: "App/b.swift", additionsText: "+1", deletionsText: "−0", isExpanded: false, isViewed: true, diff: nil, highlightedLineID: nil, threadCountText: nil, diffThreads: [:], oldPath: "App/b.swift", lineComposer: nil, canOpenOnWeb: true, isFull: false, fullHint: nil)
        var source = loaded
        source.files = [.preview, viewed]

        let model = PullRequestFileSidebarMapper.model(for: source, query: "")

        #expect(model.title == "Files 2")
        #expect(model.progressText == "1 of 2 viewed")
        #expect(model.progress == 0.5)
        #expect(model.groups == source.fileGroups)
        #expect(model.rows.map(\.id) == [PullRequestFileRowModel.preview.id, "b.swift"])
        #expect(model.rows[0].letter == "M")
        #expect(model.rows[0].folder == "ExampleUI/Calls")
        #expect(model.rows[0].isChanged == false)
        #expect(model.rows[0].threadCountText == "1")
        #expect(model.rows[0].hint == "ExampleUI/Calls/CallPresenter.swift. Click to show its diff.")
        #expect(model.rows[1].isViewed)
        #expect(model.emptyText == nil)
    }

    @Test func theQueryFiltersByPathWithoutCase() {
        let hit = PullRequestFileSidebarMapper.model(for: loaded, query: " calls/callpres ")
        let miss = PullRequestFileSidebarMapper.model(for: loaded, query: "zzz")
        var empty = loaded
        empty.files = []

        #expect(hit.rows.count == 1)
        #expect(hit.title == "Files 1")
        #expect(miss.rows.isEmpty)
        #expect(miss.emptyText == "No file matches “zzz”")
        #expect(PullRequestFileSidebarMapper.model(for: empty, query: "").emptyText == "No files")
        #expect(PullRequestFileSidebarMapper.model(for: empty, query: "").progress == 0)
    }

    @Test func theChangedSinceReviewTagMarksTheRow() {
        var changed = PullRequestFileRowModel.preview
        changed.reviewTag = PullRequestDetailsMapper.changedSinceReviewTag

        #expect(PullRequestFileSidebarMapper.row(changed).isChanged)
    }
}
