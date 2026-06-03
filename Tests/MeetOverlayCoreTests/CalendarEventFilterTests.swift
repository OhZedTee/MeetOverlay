import XCTest
@testable import MeetOverlayCore

final class CalendarEventFilterTests: XCTestCase {
    func testNilSelectedCalendarsIncludesEveryEvent() throws {
        let events = [makeEvent(id: "work-1", calendarID: "work"), makeEvent(id: "personal-1", calendarID: "personal")]

        let filteredEvents = CalendarEventFilter.events(events, selectedCalendarIDs: nil)

        XCTAssertEqual(filteredEvents.map(\.id), ["work-1", "personal-1"])
    }

    func testSelectedCalendarsIncludeOnlyMatchingEvents() throws {
        let events = [makeEvent(id: "work-1", calendarID: "work"), makeEvent(id: "personal-1", calendarID: "personal")]

        let filteredEvents = CalendarEventFilter.events(events, selectedCalendarIDs: ["personal"])

        XCTAssertEqual(filteredEvents.map(\.id), ["personal-1"])
    }

    func testEmptySelectedCalendarsIncludesNoEvents() throws {
        let events = [makeEvent(id: "work-1", calendarID: "work")]

        let filteredEvents = CalendarEventFilter.events(events, selectedCalendarIDs: [])

        XCTAssertTrue(filteredEvents.isEmpty)
    }

    private func makeEvent(id: String, calendarID: String) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: id,
            calendarID: calendarID,
            title: "Planning",
            startDate: Date(timeIntervalSinceReferenceDate: 1_000),
            endDate: Date(timeIntervalSinceReferenceDate: 2_000),
            isAllDay: false,
            participationStatus: .accepted,
            url: nil,
            notes: nil,
            location: nil
        )
    }
}
