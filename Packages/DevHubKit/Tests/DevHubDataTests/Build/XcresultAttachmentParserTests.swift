import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct XcresultAttachmentParserTests {
    @Test func readsTheManifestIntoAttachmentsInTheFolder() throws {
        let attachments = try XcresultAttachmentParser.attachments(from: XcresultFixture.manifest, folder: URL(fileURLWithPath: "/tmp/out"))

        #expect(attachments == [
            TestAttachment(testIdentifier: "LoginTests/testWrongPassword()", name: "Reference", path: "/tmp/out/5A5D6CF7-7300-4CB7-BE30-2122BE6F3D3D.png", isAssociatedWithFailure: true),
            TestAttachment(testIdentifier: "FeedUITests/testScroll()", name: "Server log", path: "/tmp/out/log.txt", isAssociatedWithFailure: false),
        ])
        #expect(attachments[0].isImage)
        #expect(attachments[1].isImage == false)
    }

    @Test func theSuggestedNameLosesTheIndexAndTheUUIDOnly() {
        #expect(XcresultAttachmentParser.displayName("Diff_image_0_B8265644-4BE6-41DD-9376-3DFDDBA704A9.png") == "Diff_image")
        #expect(XcresultAttachmentParser.displayName("plain_name.png") == "plain_name")
    }

    @Test func aBrokenManifestThrows() {
        #expect(throws: TestRunError.self) {
            try XcresultAttachmentParser.attachments(from: Data("{}".utf8), folder: URL(fileURLWithPath: "/tmp"))
        }
    }
}
