import Foundation

enum XcresultFixture {
    static let tests = Data("""
    {"devices":[{"deviceName":"My Mac","platform":"macOS"}],"testNodes":[{"name":"ExampleApp","nodeType":"Test Plan","result":"Failed","children":[{"name":"ExampleAppTests","nodeType":"Unit test bundle","result":"Failed","children":[{"name":"LoginTests","nodeType":"Test Suite","result":"Failed","children":[\
    {"name":"testLoginWorks()","nodeIdentifier":"LoginTests/testLoginWorks()","nodeType":"Test Case","result":"Passed","durationInSeconds":0.0012},\
    {"name":"testSkipped()","nodeIdentifier":"LoginTests/testSkipped()","nodeType":"Test Case","result":"Skipped","durationInSeconds":0.0016,"children":[{"name":"Test skipped - Needs a device","nodeType":"Failure Message"}]},\
    {"name":"testSlow()","nodeIdentifier":"LoginTests/testSlow()","nodeType":"Test Case","result":"Passed","durationInSeconds":0.61},\
    {"name":"testWrongPassword()","nodeIdentifier":"LoginTests/testWrongPassword()","nodeType":"Test Case","result":"Failed","durationInSeconds":0.44,"children":[{"name":"LoginTests.swift:14: XCTAssertEqual failed: (\\"locked\\") is not equal to (\\"wrongPassword\\")","nodeType":"Failure Message"}]}\
    ]}]},{"name":"ExampleAppUITests","nodeType":"UI test bundle","result":"Failed","children":[{"name":"FeedUITests","nodeType":"Test Suite","children":[\
    {"name":"testScroll()","nodeIdentifier":"FeedUITests/testScroll()","nodeType":"Test Case","result":"Failed","durationInSeconds":12.5,"children":[{"name":"Repetition 1","nodeType":"Repetition","children":[{"name":"Element not found","nodeType":"Failure Message"},{"name":"FeedUITests.swift:30","nodeType":"Source Code Reference"}]}]},\
    {"name":"testExpected()","nodeIdentifier":"FeedUITests/testExpected()","nodeType":"Test Case","result":"Expected Failure"}\
    ]}]}]}],"testPlanConfigurations":[]}
    """.utf8)

    static let manifest = Data("""
    [{"attachments":[{"configurationName":"Test Scheme Action","deviceName":"My Mac","exportedFileName":"5A5D6CF7-7300-4CB7-BE30-2122BE6F3D3D.png","isAssociatedWithFailure":true,"suggestedHumanReadableName":"Reference_0_B8265644-4BE6-41DD-9376-3DFDDBA704A9.png","timestamp":1794090226.896},{"exportedFileName":"","suggestedHumanReadableName":"broken"}],"testIdentifier":"LoginTests/testWrongPassword()"},{"attachments":[{"exportedFileName":"log.txt","suggestedHumanReadableName":"Server log.txt"}],"testIdentifier":"FeedUITests/testScroll()"}]
    """.utf8)
}
