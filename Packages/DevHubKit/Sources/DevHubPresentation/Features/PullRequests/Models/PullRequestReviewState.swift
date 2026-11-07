import Foundation
import DevHubDomain

struct PullRequestReviewState: Equatable {
    var expandedFiles: Set<PullRequestFileDiff.ID>
    var viewedFiles: Set<PullRequestFileDiff.ID>
    var focus: DiffFocus?
    var busyThreads: Set<ReviewThread.ID>
    var showsThreadsInDiff: Bool
    var openDiffThreads: Set<ReviewThread.ID>
    var showsHiddenFiles = false
    var commentDraft = ""
    var isCommentBusy = false
    var lineComment: LineCommentDraft?
    var isLineCommentBusy = false
    var jobLogs: [String: JobLogState] = [:]
    var openJobLogs: Set<String> = []
    var busyJobs: Set<String> = []
    var fullFiles: Set<PullRequestFileDiff.ID> = []
    var fileContents: [String: [String]] = [:]
    var hasCIProvider = false
    var ciToolState: CIToolState?
    var ciWorkflows: [String: CIWorkflow] = [:]
    var ciWorkflowErrors: [String: String] = [:]
    var ciFailedTests: [String: [CITestResult]] = [:]
    var ciFlakyTests: [CIFlakyTest] = []
    var ciBusyWorkflows: Set<String> = []
    var ciWorkflowDetails: [String: CIWorkflowDetails] = [:]
    var ciJobSteps: [String: [CIJobStep]] = [:]
    var ciArtifacts: [String: CIArtifactsState] = [:]
    var openJobArtifacts: Set<String> = []
    var ciDownloads: [String: CIDownloadState] = [:]
    var ciHistory: [CIWorkflowRecord] = []
    var showsCIHistory = false
    var autoRerunPlan: CIAutoRerunPlan?
    var openJobDetails: Set<String> = []
    var openTestMessages: Set<String> = []
    var openCIHistoryRuns: Set<String> = []
    var chosenHiddenFiles: Set<String> = []
    var toggledGroups: Set<String> = []
    var reviewedAt: Date?
    var changedSinceReview: [String] = []
    var showsOnlyChangedSinceReview = false

    static let initial = PullRequestReviewState(expandedFiles: [], viewedFiles: [], focus: nil, busyThreads: [], showsThreadsInDiff: true, openDiffThreads: [])
}
