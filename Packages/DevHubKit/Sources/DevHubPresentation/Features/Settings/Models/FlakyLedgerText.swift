import Foundation
import DevHubUI

enum FlakyLedgerText {
    static func title(count: Int) -> String {
        count == 0 ? "No flaky tests found by DevHub yet" : "\(CountText.count(count, "flaky test")) found by DevHub"
    }
}
