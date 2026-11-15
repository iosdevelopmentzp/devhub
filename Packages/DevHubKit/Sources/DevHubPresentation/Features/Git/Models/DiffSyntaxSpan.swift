import Foundation
import DevHubUI

struct DiffSyntaxSpan: Hashable {
    let range: Range<Int>
    let color: SyntaxColor
}
