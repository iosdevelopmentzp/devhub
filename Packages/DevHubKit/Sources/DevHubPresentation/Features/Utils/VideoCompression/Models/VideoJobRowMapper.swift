import Foundation
import DevHubDomain
import DevHubUI

enum VideoJobRowMapper {
    static func model(for job: VideoJob, isEngineReady: Bool) -> VideoJobRowModel {
        var model = VideoJobRowModel(
            id: job.id,
            title: job.name,
            source: job.source,
            facts: job.info.map(VideoCompressionText.facts) ?? ProjectPath((job.source as NSString).deletingLastPathComponent).abbreviated,
            qualityTag: TagModel(VideoCompressionText.title(for: job.settings.quality), tint: .secondary, hint: VideoCompressionText.description(for: job.settings.quality)),
            icon: "film",
            iconTint: .secondary,
            status: "",
            statusTint: .secondary,
            progress: nil,
            isWorking: false,
            resultName: nil,
            resultPath: nil,
            canStop: false,
            canRemove: true,
            canCompressAgain: false
        )
        switch job.state {
        case .waiting:
            model.status = isEngineReady ? "Waiting in the queue" : "Waiting for ffmpeg. Install it above."
            model.statusTint = isEngineReady ? .secondary : .orange
            model.canStop = true
        case .reading:
            model.status = "Reading the video…"
            model.isWorking = true
            model.canStop = true
            model.canRemove = false
        case .compressing(let progress):
            let duration = job.info?.duration ?? 0
            model.icon = "film.stack"
            model.iconTint = .blue
            model.progress = VideoCompressionPolicy.fraction(done: progress.seconds, duration: duration)
            model.status = compressingText(progress, duration: duration)
            model.statusTint = .blue
            model.canStop = true
            model.canRemove = false
        case .done(let result, let seconds):
            let original = job.info?.size ?? 0
            let isLarger = result.size > original
            model.icon = "checkmark.circle.fill"
            model.iconTint = isLarger ? .orange : .green
            model.status = VideoCompressionText.change(original: original, compressed: result.size) + " · " + DurationFormat.text(seconds)
            model.statusTint = isLarger ? .orange : .green
            model.resultName = (result.path as NSString).lastPathComponent
            model.resultPath = result.path
            model.canCompressAgain = true
        case .failed(let message):
            model.icon = "xmark.octagon.fill"
            model.iconTint = .red
            model.status = message
            model.statusTint = .red
            model.canCompressAgain = true
        case .stopped:
            model.icon = "stop.circle"
            model.status = "Stopped. No file was written."
            model.canCompressAgain = true
        }
        return model
    }

    private static func compressingText(_ progress: VideoCompressionProgress, duration: Double) -> String {
        let percent = Int((VideoCompressionPolicy.fraction(done: progress.seconds, duration: duration) * 100).rounded())
        var parts = ["Compressing \(percent) %"]
        if let remaining = VideoCompressionPolicy.remaining(done: progress.seconds, duration: duration, speed: progress.speed) {
            parts.append("\(DurationFormat.text(remaining)) left")
        }
        if let speed = progress.speed {
            parts.append(String(format: "%.1f× speed", speed))
        }
        return parts.joined(separator: " · ")
    }
}
