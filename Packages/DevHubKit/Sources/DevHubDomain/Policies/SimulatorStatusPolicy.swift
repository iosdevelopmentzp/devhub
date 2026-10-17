import Foundation

package enum SimulatorStatusPolicy {
    package static func candidates(script: String, layers: [ConfigLayerInfo], projectPath: String) -> [String] {
        guard script.hasPrefix("/") == false else { return [script] }
        let layerFolders = [ConfigLayer.user, .project, .global].compactMap { layer in
            layers.first { $0.layer == layer }?.directory
        }
        return (layerFolders + [projectPath]).map { ProjectPath($0).expanded + "/" + script }
    }

    package static func line(from lines: [String]) -> String? {
        for line in lines.reversed() {
            guard line.hasPrefix(ScriptDirectiveParser.marker) else {
                let plain = line.trimmingCharacters(in: .whitespaces)
                if plain.isEmpty == false { return plain }
                continue
            }
            guard case let .directives(directives) = ScriptDirectiveParser.parse(line) else { continue }
            for case let .view(view) in directives {
                let text = describe(view)
                if text.isEmpty == false { return text }
            }
        }
        return nil
    }

    private static func describe(_ view: ScriptView) -> String {
        guard view.pairs.isEmpty else {
            return view.pairs.map { "\($0.0): \($0.1)" }.joined(separator: " · ")
        }
        return view.text ?? ""
    }
}
