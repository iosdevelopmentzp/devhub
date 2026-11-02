import Foundation
import DevHubDomain
import DevHubUI

struct VideoJobRowModel: Identifiable, Equatable {
    let id: UUID
    var title: String
    var source: String
    var facts: String
    var qualityTag: TagModel
    var icon: String
    var iconTint: Tint
    var status: String
    var statusTint: Tint
    var progress: Double?
    var isWorking: Bool
    var resultName: String?
    var resultPath: String?
    var canStop: Bool
    var canRemove: Bool
    var canCompressAgain: Bool

    static let preview = VideoJobRowMapper.model(
        for: VideoJob(
            id: UUID(),
            source: "/Users/alex/Desktop/Screen Recording.mov",
            settings: .standard,
            info: VideoFileInfo(duration: 42.5, width: 3456, height: 2234, frameRate: 60, codec: "h264", hasAudio: false, size: 86_400_000),
            state: .compressing(VideoCompressionProgress(seconds: 17, speed: 4.2))
        ),
        isEngineReady: true
    )
}
