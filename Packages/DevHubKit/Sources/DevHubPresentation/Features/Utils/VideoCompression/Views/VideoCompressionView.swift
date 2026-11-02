import SwiftUI
import DevHubDomain
import DevHubUI

struct VideoCompressionView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(VideoCompressionStore.self) private var video
    @Environment(AppActions.self) private var appActions
    @Environment(\.panelOpenCount) private var openCount

    @State private var isDropTargeted = false

    var body: some View {
        @Bindable var video = video
        VStack(spacing: 0) {
            VideoEngineCard(
                model: VideoEngineMapper.model(for: video.engine, install: video.install, isChecking: video.isCheckingEngine),
                onInstall: video.installEngine,
                onGetHomebrew: { appActions.open(VideoCompressionText.homebrewPage) },
                onCheckAgain: { Task { await video.checkEngine() } }
            )
            .padding(.horizontal, 14)
            .padding(.top, 12)
            VideoSettingsBar(settings: $video.settings)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            VideoDropZone(isTargeted: isDropTargeted, isCompact: video.jobs.isEmpty == false, onChoose: chooseVideos)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            if video.jobs.isEmpty == false {
                Divider()
                jobList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface)
        .animation(.snappy(duration: 0.18), value: video.jobs.isEmpty)
        .dropDestination(for: URL.self) { urls, _ in
            video.add(paths: urls.filter(\.isFileURL).map(\.path))
            return true
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
        .task(id: openCount) {
            await video.checkEngine()
        }
    }

    private var rows: [VideoJobRowModel] {
        video.jobs.filter { session.matchesSearch($0.name) }.map { VideoJobRowMapper.model(for: $0, isEngineReady: video.isEngineReady) }
    }

    private var jobList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ListSectionHeader("Videos", detail: "\(video.jobs.count)") {
                    if video.hasFinishedJobs {
                        Button("Clear Finished") {
                            video.clearFinished()
                        }
                        .buttonStyle(LinkButtonStyle(.accent))
                        .hint("Removes the finished, failed and stopped rows. The files stay.")
                    }
                }
                ForEach(rows) { model in
                    VideoJobRow(
                        model: model,
                        onStop: { video.stop(model.id) },
                        onRemove: { video.remove(model.id) },
                        onCompressAgain: { video.compressAgain(model.id) },
                        onReveal: { appActions.revealInFinder(path: $0) },
                        onOpen: { appActions.openWithDefaultApp(path: $0) }
                    )
                    Divider()
                        .padding(.leading, 56)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func chooseVideos() {
        let urls = FolderPicker.chooseFiles(
            directory: ProjectPath("~/Desktop").url,
            prompt: "Compress",
            message: "Choose one or more videos. Each result goes next to its original.",
            extensions: VideoCompressionPolicy.videoExtensions.sorted()
        )
        video.add(paths: urls.map(\.path))
    }
}

#Preview {
    VideoCompressionView()
        .previewEnvironment()
}
