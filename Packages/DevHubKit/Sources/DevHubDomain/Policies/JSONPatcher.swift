import Foundation

package enum JSONPatcher {
    private enum Component {
        case key(String)
        case index(Int)
    }

    package static func apply(_ operations: [JSONPatchOperation], to data: Data) -> Data {
        guard operations.isEmpty == false,
              let root = try? JSONSerialization.jsonObject(with: data),
              root is [String: Any] || root is [Any] else { return data }
        let patched = operations.reduce(root) { current, operation in
            let path = components(of: operation.keyPath)
            guard path.isEmpty == false else { return current }
            if let value = operation.value {
                return replace(path[...], with: parsedValue(value), in: current)
            }
            return remove(path[...], in: current)
        }
        guard JSONSerialization.isValidJSONObject(patched),
              let result = try? JSONSerialization.data(withJSONObject: patched, options: [.sortedKeys, .withoutEscapingSlashes]) else { return data }
        return result
    }

    package static func isJSON(_ data: Data) -> Bool {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return false }
        return root is [String: Any] || root is [Any]
    }

    package static func parsedValue(_ text: String) -> Any {
        let trimmed = text.trimmed
        guard let data = trimmed.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) else { return text }
        return value
    }

    private static func components(of keyPath: String) -> [Component] {
        var result: [Component] = []
        for segment in keyPath.trimmed.split(separator: ".") {
            let bracket = segment.firstIndex(of: "[") ?? segment.endIndex
            let name = segment[..<bracket]
            if name.isEmpty == false {
                result.append(.key(String(name)))
            }
            for token in segment[bracket...].split(separator: "[") {
                if let index = Int(token.dropLast()) {
                    result.append(.index(index))
                }
            }
        }
        return result
    }

    private static func replace(_ path: ArraySlice<Component>, with value: Any, in current: Any?) -> Any {
        guard let head = path.first else { return value }
        let rest = path.dropFirst()
        switch head {
        case .key(let key):
            var dictionary = current as? [String: Any] ?? [:]
            dictionary[key] = replace(rest, with: value, in: dictionary[key])
            return dictionary
        case .index(let index):
            guard var array = current as? [Any], array.indices.contains(index) else { return current ?? [Any]() }
            array[index] = replace(rest, with: value, in: array[index])
            return array
        }
    }

    private static func remove(_ path: ArraySlice<Component>, in current: Any) -> Any {
        guard let head = path.first else { return current }
        let rest = path.dropFirst()
        switch head {
        case .key(let key):
            guard var dictionary = current as? [String: Any], let child = dictionary[key] else { return current }
            if rest.isEmpty {
                dictionary.removeValue(forKey: key)
            } else {
                dictionary[key] = remove(rest, in: child)
            }
            return dictionary
        case .index(let index):
            guard rest.isEmpty == false, var array = current as? [Any], array.indices.contains(index) else { return current }
            array[index] = remove(rest, in: array[index])
            return array
        }
    }
}
