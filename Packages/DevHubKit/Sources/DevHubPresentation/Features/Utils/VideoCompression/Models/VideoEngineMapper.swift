import Foundation
import DevHubDomain
import DevHubUI

enum VideoEngineMapper {
    static func model(for status: VideoEngineStatus?, install: VideoInstallState, isChecking: Bool) -> VideoEngineModel {
        switch install {
        case .running(let step):
            return VideoEngineModel(
                icon: "arrow.down.circle",
                tint: .blue,
                title: "Installing ffmpeg with Homebrew…",
                detail: step,
                action: nil,
                command: nil,
                isWorking: true,
                isCompact: false
            )
        case .failed(let message):
            return VideoEngineModel(
                icon: "xmark.octagon.fill",
                tint: .red,
                title: "Could not install ffmpeg",
                detail: message,
                action: .install("Try Again"),
                command: VideoCompressionText.installCommand,
                isWorking: false,
                isCompact: false
            )
        case .idle:
            return model(for: status, isChecking: isChecking)
        }
    }

    private static func model(for status: VideoEngineStatus?, isChecking: Bool) -> VideoEngineModel {
        switch status {
        case nil:
            return VideoEngineModel(icon: "magnifyingglass", tint: .secondary, title: "Looking for ffmpeg…", detail: "", action: nil, command: nil, isWorking: true, isCompact: true)
        case .ready(let version, let path):
            return VideoEngineModel(icon: "checkmark.circle.fill", tint: .green, title: "ffmpeg \(version)", detail: ProjectPath(path).abbreviated, action: nil, command: nil, isWorking: isChecking, isCompact: true)
        case .incomplete(let version, _, let missing):
            return VideoEngineModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "ffmpeg \(version) has no \(missing)",
                detail: "DevHub needs ffmpeg with ffprobe and the libx264 encoder. The Homebrew build has both. Run the command in Terminal, then check again.",
                action: .checkAgain,
                command: VideoCompressionText.reinstallCommand,
                isWorking: isChecking,
                isCompact: false
            )
        case .missing(let homebrew?):
            return VideoEngineModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "ffmpeg is not installed",
                detail: "DevHub compresses videos with ffmpeg. Homebrew (\(ProjectPath(homebrew).abbreviated)) installs it in about a minute, without a password.",
                action: .install("Install ffmpeg"),
                command: VideoCompressionText.installCommand,
                isWorking: isChecking,
                isCompact: false
            )
        case .missing(nil):
            return VideoEngineModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "ffmpeg and Homebrew are not installed",
                detail: "DevHub installs ffmpeg with Homebrew. Get Homebrew: download the .pkg file from its releases page and open it. Then press Check Again.",
                action: .getHomebrew,
                command: VideoCompressionText.installCommand,
                isWorking: isChecking,
                isCompact: false
            )
        }
    }
}
