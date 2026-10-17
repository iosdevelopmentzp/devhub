import Foundation

package enum SimulatorStatusParser {
    package static func parse(_ lines: [String]) -> String? {
        for line in lines.reversed() {
            if line.hasPrefix(ScriptDirectiveParser.marker) {
                if case let .directives(directives) = ScriptDirectiveParser.parse(line) {
                    for case let .view(view) in directives {
                        let text = describe(view)
                        if text.isEmpty == false {
                            return text
                        }
                    }
                }
                continue
            }
            let plain = line.trimmingCharacters(in: .whitespaces)
            if plain.isEmpty == false {
                return plain
            }
        }
        return nil
    }

    private static func describe(_ view: ScriptView) -> String {
        if view.pairs.isEmpty == false {
            return view.pairs.map { "\($0.0): \($0.1)" }.joined(separator: " · ")
        }
        return view.text ?? ""
    }
}
