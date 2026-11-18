import Foundation
import DevHubUI

extension PullRequestDetailsModel.AutoRerun {
    mutating func add(_ notice: CIAutoRerunNotice?) {
        guard let notice else { return }
        self.notice = notice.text
        noticeHint = notice.detail
        noticeTint = notice.isProblem ? .orange : .green
    }
}
