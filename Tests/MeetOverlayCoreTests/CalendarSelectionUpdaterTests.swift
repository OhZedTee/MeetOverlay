import XCTest
@testable import MeetOverlayCore

final class CalendarSelectionUpdaterTests: XCTestCase {
    func testUnselectingFromAllCalendarsStoresRemainingCalendarIDs() throws {
        let selectedCalendarIDs = CalendarSelectionUpdater.updatedSelection(
            currentSelection: nil,
            allCalendarIDs: ["work", "personal", "birthdays"],
            calendarID: "birthdays",
            isSelected: false
        )

        XCTAssertEqual(selectedCalendarIDs, ["work", "personal"])
    }

    func testSelectingEveryCalendarReturnsNilAllCalendarsSelection() throws {
        let selectedCalendarIDs = CalendarSelectionUpdater.updatedSelection(
            currentSelection: ["work", "personal"],
            allCalendarIDs: ["work", "personal", "birthdays"],
            calendarID: "birthdays",
            isSelected: true
        )

        XCTAssertNil(selectedCalendarIDs)
    }

    func testUnselectingLastCalendarStoresEmptySelection() throws {
        let selectedCalendarIDs = CalendarSelectionUpdater.updatedSelection(
            currentSelection: ["work"],
            allCalendarIDs: ["work"],
            calendarID: "work",
            isSelected: false
        )

        XCTAssertEqual(selectedCalendarIDs, [])
    }
}
