import Foundation

struct DiffLineChunk<Element: Identifiable>: Identifiable {
    let id: Element.ID
    let elements: [Element]

    static var size: Int { 24 }

    static func chunks(of elements: [Element], size: Int) -> [DiffLineChunk<Element>] {
        stride(from: 0, to: elements.count, by: size).map { start in
            let slice = Array(elements[start..<min(start + size, elements.count)])
            return DiffLineChunk(id: slice[0].id, elements: slice)
        }
    }
}
