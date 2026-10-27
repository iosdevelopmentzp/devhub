import Foundation

enum JobLogState: Equatable {
    case loading
    case loaded(String)
    case failure(String)
}
