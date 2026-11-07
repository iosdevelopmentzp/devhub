import Foundation
import DevHubDomain

struct CIDiagnosticsSnapshot: Equatable {
    var requestReference: String?
    var requestWorkflows: [CIWorkflow] = []
    var requestWorkflowErrors: [String: String] = [:]
    var branchRun: CIRun?
    var branchWorkflows: [CIWorkflow] = []
    var baseRun: CIRun?
    var baseWorkflows: [CIWorkflow] = []
}
