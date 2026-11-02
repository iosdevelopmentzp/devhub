import Foundation
import DevHubDomain

struct VideoJob: Identifiable, Equatable {
    enum State: Equatable {
        case waiting
        case reading
        case compressing(VideoCompressionProgress)
        case done(VideoCompressionResult, seconds: Double)
        case failed(String)
        case stopped
    }

    let id: UUID
    let source: String
    let settings: VideoCompressionSettings
    var info: VideoFileInfo?
    var state: State

    var name: String {
        (source as NSString).lastPathComponent
    }

    var isRunning: Bool {
        switch state {
        case .reading, .compressing: true
        default: false
        }
    }

    var isFinished: Bool {
        switch state {
        case .done, .failed, .stopped: true
        default: false
        }
    }
}
