import AppKit
import DevHubDomain
import DevHubUI

@MainActor
enum PasteboardWriter {

    static func write(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
