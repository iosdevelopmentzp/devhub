import Foundation

package struct CrashReport: Identifiable, Hashable, Sendable {
    package struct Frame: Hashable, Sendable {
        package var image: String
        package var symbol: String?
        package var file: String?
        package var line: Int?
        package var isApp: Bool

        package init(image: String, symbol: String?, file: String?, line: Int?, isApp: Bool) {
            self.image = image
            self.symbol = symbol
            self.file = file
            self.line = line
            self.isApp = isApp
        }
    }

    package let path: String
    package var processName: String
    package var bundleID: String?
    package var appVersion: String?
    package var date: Date
    package var simulatorID: String?
    package var exceptionType: String?
    package var signal: String?
    package var subtype: String?
    package var messages: [String]
    package var frames: [Frame]

    package var id: String {
        path
    }

    package init(
        path: String,
        processName: String,
        bundleID: String?,
        appVersion: String?,
        date: Date,
        simulatorID: String?,
        exceptionType: String?,
        signal: String?,
        subtype: String?,
        messages: [String],
        frames: [Frame]
    ) {
        self.path = path
        self.processName = processName
        self.bundleID = bundleID
        self.appVersion = appVersion
        self.date = date
        self.simulatorID = simulatorID
        self.exceptionType = exceptionType
        self.signal = signal
        self.subtype = subtype
        self.messages = messages
        self.frames = frames
    }
}
