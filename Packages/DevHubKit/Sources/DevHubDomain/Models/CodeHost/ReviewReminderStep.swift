import Foundation

package struct ReviewReminderStep: Hashable, Sendable {
    package let waits: [ReviewWait]
    package let due: [ReviewWait]

    package init(waits: [ReviewWait], due: [ReviewWait]) {
        self.waits = waits
        self.due = due
    }
}
