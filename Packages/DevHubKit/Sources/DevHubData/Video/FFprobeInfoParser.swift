import Foundation
import DevHubDomain

enum FFprobeInfoParser {
    static func parse(_ json: String) -> VideoFileInfo? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let output = try? decoder.decode(Output.self, from: Data(json.utf8)) else { return nil }
        guard let video = output.streams.first(where: { $0.codecType == "video" }), let width = video.width, let height = video.height else { return nil }
        let isTurned = (video.sideDataList ?? []).contains { abs($0.rotation ?? 0) % 180 == 90 }
        return VideoFileInfo(
            duration: Double(output.format?.duration ?? "") ?? Double(video.duration ?? "") ?? 0,
            width: isTurned ? height : width,
            height: isTurned ? width : height,
            frameRate: rate(video.avgFrameRate) ?? rate(video.rFrameRate),
            codec: video.codecName ?? "unknown",
            hasAudio: output.streams.contains { $0.codecType == "audio" },
            size: Int64(output.format?.size ?? "") ?? 0
        )
    }

    private static func rate(_ text: String?) -> Double? {
        guard let parts = text?.split(separator: "/"), parts.count == 2, let top = Double(parts[0]), let bottom = Double(parts[1]), top > 0, bottom > 0 else { return nil }
        return top / bottom
    }

    private struct Output: Decodable {
        let streams: [Stream]
        let format: Format?
    }

    private struct Stream: Decodable {
        let codecType: String?
        let codecName: String?
        let width: Int?
        let height: Int?
        let avgFrameRate: String?
        let rFrameRate: String?
        let duration: String?
        let sideDataList: [SideData]?
    }

    private struct SideData: Decodable {
        let rotation: Int?
    }

    private struct Format: Decodable {
        let duration: String?
        let size: String?
    }
}
