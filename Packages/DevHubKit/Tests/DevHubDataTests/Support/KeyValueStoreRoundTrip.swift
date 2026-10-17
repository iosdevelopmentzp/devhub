import DevHubDomain
import Foundation
import Testing

enum KeyValueStoreRoundTrip {
    static func string(_ store: any KeyValueStore) {
        #expect(store.string(forKey: "string") == nil)
        store.set("value" as String?, forKey: "string")
        #expect(store.string(forKey: "string") == "value")
        store.set(nil as String?, forKey: "string")
        #expect(store.string(forKey: "string") == nil)
    }

    static func strings(_ store: any KeyValueStore) {
        #expect(store.strings(forKey: "strings") == nil)
        store.set(["a", "b"], forKey: "strings")
        #expect(store.strings(forKey: "strings") == ["a", "b"])
    }

    static func bool(_ store: any KeyValueStore) {
        #expect(store.bool(forKey: "bool") == false)
        store.set(true, forKey: "bool")
        #expect(store.bool(forKey: "bool"))
    }

    static func integer(_ store: any KeyValueStore) {
        #expect(store.integer(forKey: "integer") == 0)
        store.set(42, forKey: "integer")
        #expect(store.integer(forKey: "integer") == 42)
    }

    static func doubles(_ store: any KeyValueStore) {
        #expect(store.doubles(forKey: "doubles") == nil)
        store.set([1.5, 2.25], forKey: "doubles")
        #expect(store.doubles(forKey: "doubles") == [1.5, 2.25])
    }

    static func stringMap(_ store: any KeyValueStore) {
        #expect(store.stringMap(forKey: "map") == nil)
        store.set(["a": "1", "b": "2"], forKey: "map")
        #expect(store.stringMap(forKey: "map") == ["a": "1", "b": "2"])
    }

    static func data(_ store: any KeyValueStore) {
        #expect(store.data(forKey: "data") == nil)
        store.set(Data([1, 2, 3]) as Data?, forKey: "data")
        #expect(store.data(forKey: "data") == Data([1, 2, 3]))
        store.set(nil as Data?, forKey: "data")
        #expect(store.data(forKey: "data") == nil)
    }

    static func remove(_ store: any KeyValueStore) {
        store.set("value" as String?, forKey: "key")
        store.remove(forKey: "key")
        #expect(store.string(forKey: "key") == nil)
    }

    static func codable(_ store: any KeyValueStore) {
        let settings = AppSettings(showDockIcon: true, globalShortcut: .controlOptionD, editor: "VS Code")
        store.encode(settings, forKey: "settings")
        #expect(store.decode(AppSettings.self, forKey: "settings") == settings)
        store.encode(nil as AppSettings?, forKey: "settings")
        #expect(store.data(forKey: "settings") == nil)
        store.set(Data("garbage".utf8) as Data?, forKey: "settings")
        #expect(store.decode(AppSettings.self, forKey: "settings") == nil)
    }
}
