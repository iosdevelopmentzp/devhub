import Foundation
import DevHubDomain

enum DeviceChromeParser {
    static func chrome(from data: Data) throws -> DeviceChrome {
        let file = try JSONDecoder().decode(File.self, from: data)
        let images = file.images
        return DeviceChrome(
            pieces: DeviceChrome.Pieces(
                topLeft: images.topLeft,
                top: images.top,
                topRight: images.topRight,
                right: images.right,
                bottomRight: images.bottomRight,
                bottom: images.bottom,
                bottomLeft: images.bottomLeft,
                left: images.left
            ),
            composite: images.composite,
            sizing: DeviceChrome.Insets(top: images.sizing.topHeight, left: images.sizing.leftWidth, bottom: images.sizing.bottomHeight, right: images.sizing.rightWidth),
            padding: images.devicePadding.map { DeviceChrome.Insets(top: $0.top, left: $0.left, bottom: $0.bottom, right: $0.right) } ?? .zero,
            buttons: (file.inputs ?? []).compactMap(button),
            outline: file.paths?.simpleOutsideBorder.map(outline)
        )
    }

    private static func outline(_ border: File.Border) -> DeviceChrome.Outline {
        DeviceChrome.Outline(
            insets: border.insets.map { DeviceChrome.Insets(top: $0.top, left: $0.left, bottom: $0.bottom, right: $0.right) } ?? .zero,
            cornerWidth: border.cornerRadiusX,
            cornerHeight: border.cornerRadiusY
        )
    }

    private static func button(_ input: File.Input) -> DeviceChrome.Button? {
        guard let image = input.image, let offset = input.offsets?.normal else { return nil }
        return DeviceChrome.Button(
            image: image,
            anchor: input.anchor ?? "left",
            align: input.align ?? "leading",
            onTop: input.onTop ?? false,
            x: offset.x,
            y: offset.y
        )
    }

    private struct File: Decodable {
        struct Sizing: Decodable {
            let leftWidth: Double
            let rightWidth: Double
            let topHeight: Double
            let bottomHeight: Double
        }

        struct Padding: Decodable {
            let top: Double
            let left: Double
            let bottom: Double
            let right: Double
        }

        struct Images: Decodable {
            let topLeft: String
            let top: String
            let topRight: String
            let right: String
            let bottomRight: String
            let bottom: String
            let bottomLeft: String
            let left: String
            let composite: String?
            let sizing: Sizing
            let devicePadding: Padding?
        }

        struct Border: Decodable {
            let insets: Padding?
            let cornerRadiusX: Double
            let cornerRadiusY: Double
        }

        struct Paths: Decodable {
            let simpleOutsideBorder: Border?
        }

        struct Offset: Decodable {
            let x: Double
            let y: Double
        }

        struct Offsets: Decodable {
            let normal: Offset
        }

        struct Input: Decodable {
            let image: String?
            let anchor: String?
            let align: String?
            let onTop: Bool?
            let offsets: Offsets?
        }

        let images: Images
        let inputs: [Input]?
        let paths: Paths?
    }
}
