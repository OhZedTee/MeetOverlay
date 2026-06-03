import XCTest
@testable import MeetOverlayCore

final class GoogleMeetLinkFinderTests: XCTestCase {
    func testFindsMeetLinkInEventText() throws {
        let text = "Join with Google Meet: https://meet.google.com/abc-defg-hij"

        let url = GoogleMeetLinkFinder.firstLink(in: [text])

        XCTAssertEqual(url?.absoluteString, "https://meet.google.com/abc-defg-hij")
    }
}
