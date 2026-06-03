import XCTest
@testable import MeetOverlayCore

final class MeetingCountdownFormatterTests: XCTestCase {
    func testShowsRoundedUpMinutesBeforeStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(119)),
            "Starts in 2 minutes"
        )
    }

    func testShowsSingularMinuteBeforeStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(60)),
            "Starts in 1 minute"
        )
    }

    func testShowsSecondsNearStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(30)),
            "Starts in 30 seconds"
        )
    }

    func testShowsStartedTextAfterStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(-90)),
            "Started 2 minutes ago"
        )
    }
}
