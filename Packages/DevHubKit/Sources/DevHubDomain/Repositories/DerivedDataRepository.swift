import Foundation

package protocol DerivedDataRepository: Sendable {
    func folder(forCheckout checkout: String) -> URL?
    func size(of folder: URL) async -> Int64?
    func remove(_ folder: URL) throws
}
