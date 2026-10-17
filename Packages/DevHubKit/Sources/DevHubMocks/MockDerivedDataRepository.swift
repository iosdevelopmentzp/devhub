import Foundation
import DevHubDomain

struct MockDerivedDataRepository: DerivedDataRepository {

    func folder(forCheckout checkout: String) -> URL? {
        nil
    }

    func size(of folder: URL) async -> Int64? {
        nil
    }

    func remove(_ folder: URL) throws {}
}
