import AppKit
import DevHubDomain
import DevHubUI

enum StatusItemImage {
    static func image(for state: StatusItemState) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: state.symbolName, accessibilityDescription: "DevHub") else { return nil }
        guard state.showsFailureDot else {
            symbol.isTemplate = true
            return symbol
        }
        let size = symbol.size
        let image = NSImage(size: size, flipped: false) { rect in
            let tinted = symbol.copy() as? NSImage ?? symbol
            tinted.isTemplate = true
            NSColor.labelColor.set()
            tinted.draw(in: rect)
            rect.fill(using: .sourceAtop)
            let diameter = max(5, rect.width * 0.38)
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.maxX - diameter, y: rect.minY, width: diameter, height: diameter)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
