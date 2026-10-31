import Foundation

package enum OperationScope {
    @TaskLocal package static var current: UUID?
}
