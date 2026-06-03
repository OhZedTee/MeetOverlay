import XCTest
@testable import MeetOverlayCore

final class MeetingAlertSelectorTests: XCTestCase {
    func testShowsUpcomingMeetEventInsideAlertWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: now.addingTimeInterval(60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], suppressedEventIDs: [])

        XCTAssertEqual(selectedMeeting?.eventID, "event-1")
        XCTAssertEqual(selectedMeeting?.meetURL.absoluteString, "https://meet.google.com/abc-defg-hij")
    }

    func testDoesNotShowDeclinedEvent() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Declined planning",
            startDate: now.addingTimeInterval(60),
            now: now,
            participationStatus: .declined
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], suppressedEventIDs: [])

        XCTAssertNil(selectedMeeting)
    }

    func testDoesNotShowSuppressedEvent() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: now.addingTimeInterval(60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], suppressedEventIDs: ["event-1"])

        XCTAssertNil(selectedMeeting)
    }

    func testDoesNotShowEventBeforeAlertWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Later planning",
            startDate: now.addingTimeInterval(61),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], suppressedEventIDs: [])

        XCTAssertNil(selectedMeeting)
    }

    func testDoesNotShowEventThatStartedTooLongAgo() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Already started",
            startDate: now.addingTimeInterval(-25 * 60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60, lateAlertGraceTime: 120)
            .meetingToShow(now: now, events: [event], suppressedEventIDs: [])

        XCTAssertNil(selectedMeeting)
    }

    func testShowsEventThatJustStarted() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Just started",
            startDate: now.addingTimeInterval(-30),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60, lateAlertGraceTime: 120)
            .meetingToShow(now: now, events: [event], suppressedEventIDs: [])

        XCTAssertEqual(selectedMeeting?.eventID, "event-1")
    }

    private func makeEvent(
        id: String,
        title: String,
        startDate: Date,
        now: Date,
        participationStatus: EventParticipationStatus = .accepted
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: id,
            title: title,
            startDate: startDate,
            endDate: now.addingTimeInterval(3_600),
            isAllDay: false,
            participationStatus: participationStatus,
            url: nil,
            notes: "https://meet.google.com/abc-defg-hij",
            location: nil
        )
    }
}
