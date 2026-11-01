import Foundation

enum DeviceChromeFixture {
    static let phone = #"""
    {
      "identifier": "com.apple.dt.devicekit.chrome.phone11",
      "images": {
        "topLeft": "Phone TL", "top": "Phone Top", "topRight": "Phone TR", "right": "Phone Right",
        "bottomRight": "Phone BR", "bottom": "Phone Base", "bottomLeft": "Phone BL", "left": "Phone Left",
        "composite": "PhoneComposite", "screen": "Screen",
        "sizing": { "leftWidth": 18, "rightWidth": 18, "topHeight": 18, "bottomHeight": 18 },
        "padding": { "width": 9, "height": 0 },
        "devicePadding": { "top": 0, "left": 9, "bottom": 0, "right": 9 }
      },
      "paths": { "simpleOutsideBorder": { "insets": { "top": 0, "left": 2, "bottom": 0, "right": 2 }, "cornerRadiusX": 80, "cornerRadiusY": 80 } },
      "inputs": [
        { "name": "action", "type": "button", "image": "Mute BTN", "onTop": false, "anchor": "left", "align": "leading", "offsets": { "normal": { "x": 8, "y": 160 }, "rollover": { "x": 3, "y": 160 } } },
        { "name": "power", "type": "button", "image": "X_Power BTN", "onTop": false, "anchor": "right", "align": "leading", "offsets": { "normal": { "x": -8, "y": 262 } } },
        { "name": "home", "type": "button" }
      ]
    }
    """#

    static let tablet = #"""
    {
      "images": {
        "topLeft": "iPad TL", "top": "iPadTop", "topRight": "iPad TR", "right": "iPadRight",
        "bottomRight": "iPad BR", "bottom": "iPadBase", "bottomLeft": "iPad BL", "left": "iPadLeft",
        "screen": "Screen",
        "sizing": { "leftWidth": 59, "rightWidth": 59, "topHeight": 59, "bottomHeight": 59 },
        "devicePadding": { "top": 10, "left": 0, "bottom": 0, "right": 10 }
      },
      "inputs": [
        { "name": "power", "image": "iPad Power BTN", "onTop": false, "anchor": "top", "align": "trailing", "offsets": { "normal": { "x": -84, "y": 8 } } }
      ]
    }
    """#

    static let composite = #"""
    {
      "images": {
        "topLeft": "TL", "top": "T", "topRight": "TR", "right": "R",
        "bottomRight": "BR", "bottom": "B", "bottomLeft": "BL", "left": "L",
        "composite": "Composite",
        "sizing": { "leftWidth": 10, "rightWidth": 10, "topHeight": 10, "bottomHeight": 10 }
      },
      "paths": { "simpleOutsideBorder": { "cornerRadiusX": 40, "cornerRadiusY": 40 } }
    }
    """#
}
