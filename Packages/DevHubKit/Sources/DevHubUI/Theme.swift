import SwiftUI

package enum Theme {
    package static let base = Color(white: 0.97)
    package static let surface = Color.white
    package static let border = Color.primary.opacity(0.12)
    package static let hover = Color.primary.opacity(0.05)
    package static let shadow = Color.black.opacity(0.08)

    package static let syntaxKeyword = Color(red: 0.68, green: 0.24, blue: 0.64)
    package static let syntaxType = Color(red: 0.04, green: 0.31, blue: 0.47)
    package static let syntaxString = Color(red: 0.82, green: 0.18, blue: 0.11)
    package static let syntaxNumber = Color(red: 0.15, green: 0.16, blue: 0.85)
    package static let syntaxComment = Color(red: 0.44, green: 0.50, blue: 0.55)
    package static let syntaxAttribute = Color(red: 0.58, green: 0.44, blue: 0.00)
    package static let syntaxDirective = Color(red: 0.47, green: 0.29, blue: 0.16)
}
