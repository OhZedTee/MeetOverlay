import XCTest
@testable import MeetOverlayCore

final class SnoozeDurationFormatterTests: XCTestCase {
    func testWholeMinutesUseMinuteWording() throws {
        XCTAssertEqual(SnoozeDurationFormatter.label(300), "5 minutes")
        XCTAssertEqual(SnoozeDurationFormatter.label(60), "1 minute")
    }

    func testNonWholeMinutesFallBackToSeconds() throws {
        XCTAssertEqual(SnoozeDurationFormatter.label(90), "90 seconds")
        XCTAssertEqual(SnoozeDurationFormatter.label(30), "30 seconds")
        XCTAssertEqual(SnoozeDurationFormatter.label(1), "1 second")
    }
}

final class SnoozeNotificationActionTests: XCTestCase {
    func testIdentifierRoundTripsDuration() throws {
        let identifier = SnoozeNotificationAction.identifier(for: 300)

        XCTAssertEqual(SnoozeNotificationAction.duration(fromIdentifier: identifier), 300)
    }

    func testIdentifierEncodesWholeSeconds() throws {
        XCTAssertEqual(SnoozeNotificationAction.identifier(for: 90), "SNOOZE_ACTION:90")
    }

    func testNonSnoozeIdentifiersDecodeToNil() throws {
        XCTAssertNil(SnoozeNotificationAction.duration(fromIdentifier: "JOIN_MEETING"))
        XCTAssertNil(SnoozeNotificationAction.duration(fromIdentifier: "com.apple.UNNotificationDefaultActionIdentifier"))
    }

    func testMalformedDurationsDecodeToNil() throws {
        XCTAssertNil(SnoozeNotificationAction.duration(fromIdentifier: "SNOOZE_ACTION:"))
        XCTAssertNil(SnoozeNotificationAction.duration(fromIdentifier: "SNOOZE_ACTION:abc"))
        XCTAssertNil(SnoozeNotificationAction.duration(fromIdentifier: "SNOOZE_ACTION:-5"))
        XCTAssertNil(SnoozeNotificationAction.duration(fromIdentifier: "SNOOZE_ACTION:0"))
    }
}
