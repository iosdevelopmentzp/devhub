import Foundation

enum CircleCIFixture {
    static let workflowID = "11111111-2222-3333-4444-555555555555"
    static let runID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

    static let version = Data(#"""
    {"version":"1.13.0","commit":"0a1b2c3d","modified":false,"latest":"1.13.0","outdated":false,"upgrade_command":"brew upgrade circleci"}
    """#.utf8)

    static let oldVersionText = "circleci version 0.1.31425+1f2e3d4c (release)\n"

    static let settingsLoggedIn = Data(#"""
    {"host":"https://ci.example.com","telemetry":true,"theme":"auto","token_set":true,"update_check":true}
    """#.utf8)

    static let settingsLoggedOut = Data(#"""
    {"host":"https://ci.example.com","telemetry":true,"theme":"auto","token_set":false,"update_check":true}
    """#.utf8)

    static let workflow = Data(#"""
    {"id":"11111111-2222-3333-4444-555555555555","name":"build-and-test","phase":"finished","outcome":"failed","current_outcome":"failed","run_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","created_at":"2026-10-30T10:00:00Z","ended_at":"2026-10-30T10:12:30Z","jobs":[{"id":"job-build","name":"build","phase":"finished","outcome":"success","current_outcome":"success","type":"build"},{"id":"job-unit-tests","name":"unit-tests","phase":"finished","outcome":"failed","current_outcome":"failed","type":"build"},{"id":"job-approve-release","name":"approve-release","phase":"on_hold","outcome":"unknown","current_outcome":"unknown","type":"approval"},{"id":"job-deploy","name":"deploy","phase":"blocked","outcome":null,"current_outcome":null,"type":"build"}]}
    """#.utf8)

    static let runningWorkflow = Data(#"""
    {"id":"11111111-2222-3333-4444-555555555555","name":"build-and-test","phase":"running","outcome":"unknown","current_outcome":"running","run_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","jobs":[]}
    """#.utf8)

    static let runs = Data(#"""
    [{"id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","phase":"finished","outcome":"failed","current_outcome":"failed","branch":"feature/ABC-123-short-title","tag":null,"revision":"aaa111bbb222","created_at":"2026-10-30T10:00:00Z"},{"id":"ffffffff-1111-2222-3333-444444444444","phase":"running","outcome":"unknown","current_outcome":"running","branch":"main","tag":null,"revision":"ccc333ddd444","created_at":"2026-10-30T09:00:00.123Z"},{"id":"","phase":"finished"}]
    """#.utf8)

    static let runsPage = Data(#"""
    {"items":[{"id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","phase":"finished","outcome":"success","branch":"main"}],"next_page_token":null}
    """#.utf8)

    static let jobOutput = Data(#"""
    {"steps":[{"num":0,"name":"Spin up environment","type":"infrastructure","phase":"finished","outcome":"success","exit_code":0,"command":"","output":"Build-agent version 1.0.0\n"},{"num":1,"name":"Run tests","type":"run","phase":"finished","outcome":"failed","exit_code":65,"command":"swift test","output":"\u001b[31mTest Case failed\u001b[0m\nExecuted 2 tests\n"}]}
    """#.utf8)

    static let testResults = Data(#"""
    {"classname":"LoginViewModelTests","name":"testRetryAfterTimeout","result":"failure","run_time":2.4,"message":"XCTAssertEqual failed"}
    {"classname":"ProfileBadgeTests","name":"testBadgeCount","result":"failure","run_time":0.1,"message":""}

    """#.utf8)

    static let testResultsArray = Data(#"""
    [{"classname":"LoginViewModelTests","name":"testRetryAfterTimeout","result":"failure","run_time":2.4,"message":"XCTAssertEqual failed"},{"classname":"","name":"","result":"failure"}]
    """#.utf8)

    static let flakyTests = Data(#"""
    {"flaky-tests":[{"time-wasted":120,"workflow-created-at":"2026-10-29T10:00:00Z","workflow-id":"11111111-2222-3333-4444-555555555555","classname":"LoginViewModelTests","pipeline-number":42,"workflow-name":"build-and-test","test-name":"testRetryAfterTimeout","job-name":"unit-tests","job-number":7,"times-flaked":7,"source":"junit","file":"Tests/LoginViewModelTests.swift"},{"classname":"","test-name":"","times-flaked":1}],"total-flaky-tests":2}
    """#.utf8)

    static let workflowV3 = Data(#"""
    {"id":"11111111-2222-3333-4444-555555555555","name":"build-and-test","phase":"started","current_outcome":"failed","run_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","created_at":"2026-10-30T10:00:00Z","jobs":[{"id":"job-build","name":"build","phase":"ended","outcome":"succeeded","current_outcome":"succeeded","type":"build"},{"id":"job-unit-tests","name":"unit-tests","phase":"ended","outcome":"failed","current_outcome":"failed","type":"build"},{"id":"job-approve-release","name":"approve-release","phase":"started","type":"approval"},{"id":"job-deploy","name":"deploy","phase":"created","type":"build"}]}
    """#.utf8)

    static let workflowV2 = Data(#"""
    {"pipeline_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","id":"11111111-2222-3333-4444-555555555555","name":"build-and-test","project_slug":"gh/example/app","status":"failed","started_by":"33333333-4444-5555-6666-777777777777","pipeline_number":42,"created_at":"2026-10-30T10:00:00Z","stopped_at":"2026-10-30T10:12:30Z"}
    """#.utf8)

    static let workflowJobsV2 = Data(#"""
    {"next_page_token":null,"items":[{"dependencies":[],"job_number":101,"id":"job-build","started_at":"2026-10-30T10:00:10Z","name":"build","project_slug":"gh/example/app","status":"success","type":"build","stopped_at":"2026-10-30T10:04:00Z"},{"dependencies":["job-build"],"job_number":102,"id":"job-unit-tests","started_at":"2026-10-30T10:04:05Z","name":"unit-tests","project_slug":"gh/example/app","status":"failed","type":"build","stopped_at":"2026-10-30T10:12:30Z"},{"dependencies":["job-unit-tests"],"id":"job-approve-release","started_at":null,"name":"approve-release","project_slug":"gh/example/app","status":"on_hold","type":"approval","approval_request_id":"44444444-5555-6666-7777-888888888888","stopped_at":null},{"id":"","name":"ghost"}]}
    """#.utf8)

    static let jobV3 = Data(#"""
    {"id":"job-unit-tests","name":"unit-tests","type":"build","phase":"ended","outcome":"failed","started_at":"2026-10-30T10:04:05Z","stopped_at":"2026-10-30T10:12:30Z","project_id":"p1","pipeline_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","workflow_id":"11111111-2222-3333-4444-555555555555","executions":[{"index":0,"steps":[{"name":"Spin up environment","type":"infrastructure","num":0,"phase":"ended","outcome":"succeeded","exit_code":0,"started_at":"2026-10-30T10:04:05Z","stopped_at":"2026-10-30T10:04:08Z"},{"name":"Run tests","type":"run","num":1,"phase":"ended","outcome":"failed","exit_code":1,"command":"swift test","started_at":"2026-10-30T10:04:08Z","stopped_at":"2026-10-30T10:05:00Z"}]},{"index":1,"steps":[{"name":"Spin up environment","type":"infrastructure","num":0,"phase":"ended","outcome":"succeeded","exit_code":0,"started_at":"2026-10-30T10:04:05Z","stopped_at":"2026-10-30T10:04:07Z"},{"name":"Checkout code","type":"checkout","num":1,"phase":"ended","outcome":"succeeded","exit_code":0,"started_at":"2026-10-30T10:04:07Z","stopped_at":"2026-10-30T10:04:15Z"},{"name":"Run tests","type":"run","num":2,"phase":"ended","outcome":"failed","exit_code":65,"command":"swift test","started_at":"2026-10-30T10:04:15Z","stopped_at":"2026-10-30T10:11:47Z"},{"name":"Upload test results","type":"test_results","num":3,"phase":"started"}]}]}
    """#.utf8)

    static let artifacts = Data(#"""
    [{"path":"test-results/junit.xml","url":"https://app.circleci.example.com/artifacts/0/test-results/junit.xml","execution":0},{"path":"screenshots/LoginTests.png","url":"https://app.circleci.example.com/artifacts/0/screenshots/LoginTests.png","execution":0},{"path":"","url":"x"}]
    """#.utf8)

    static let workflowList = Data(#"""
    [{"run_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","id":"11111111-2222-3333-4444-555555555555","name":"build-and-test","phase":"ended","outcome":"failed","current_outcome":"failed"},{"id":"77777777-8888-9999-aaaa-bbbbbbbbbbbb","name":"nightly","phase":"started","current_outcome":"succeeded"},{"id":""}]
    """#.utf8)

    static let runsV3 = Data(#"""
    [{"id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","phase":"ended","current_outcome":"failed","branch":"feature/ABC-123-short-title","revision":"aaa111bbb222","repository_url":"https://github.com/example/app","commit":{"subject":"ABC-123: Retry the login","url":"https://github.com/example/app/commit/aaa111bbb222","author_name":"Alex","author_login":"alex"},"created_at":"2026-10-30T10:00:00Z"}]
    """#.utf8)
}
