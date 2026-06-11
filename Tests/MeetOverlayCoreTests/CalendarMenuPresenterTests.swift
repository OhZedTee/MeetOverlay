import XCTest
@testable import MeetOverlayCore

final class CalendarMenuPresenterTests: XCTestCase {
    func testBuildsTodayAndTomorrowSectionsWithMeetIndicators() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let todayMeet = makeEvent(
            id: "today-meet",
            title: "Planning",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 0, calendar: calendar),
            notes: "https://meet.google.com/abc-defg-hij"
        )
        let tomorrowNoMeet = makeEvent(
            id: "tomorrow-no-meet",
            title: "Admin day",
            startDate: date(year: 2026, month: 6, day: 4, hour: 9, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 4, hour: 17, minute: 0, calendar: calendar),
            isAllDay: true
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(now: now, events: [tomorrowNoMeet, todayMeet])

        XCTAssertEqual(sections.map(\.title), ["Today's Events", "Tomorrow's Events"])
        XCTAssertEqual(sections[0].rows[0].title, "Planning")
        XCTAssertEqual(sections[0].rows[0].timeText, "17:00")
        XCTAssertEqual(sections[0].rows[0].durationText, "1h")
        XCTAssertTrue(sections[0].rows[0].hasMeetLink)
        XCTAssertEqual(sections[0].rows[0].meetURL?.absoluteString, "https://meet.google.com/abc-defg-hij")
        XCTAssertEqual(sections[0].rows[0].platform, .googleMeet)
        XCTAssertEqual(sections[1].rows[0].title, "Admin day")
        XCTAssertEqual(sections[1].rows[0].timeText, "All-day")
        XCTAssertNil(sections[1].rows[0].durationText, "All-day events show no duration")
        XCTAssertFalse(sections[1].rows[0].hasMeetLink)
        XCTAssertNil(sections[1].rows[0].meetURL)
        XCTAssertNil(sections[1].rows[0].platform)
    }

    func testRowDurationCoversPartialHours() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let event = makeEvent(
            id: "event-1",
            title: "Sprint planning",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 30, calendar: calendar)
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(now: now, events: [event])

        XCTAssertEqual(sections[0].rows[0].durationText, "1h 30m")
    }

    func testRowsDetectNonMeetPlatforms() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let zoomEvent = makeEvent(
            id: "zoom-event",
            title: "Zoom sync",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 0, calendar: calendar),
            notes: "https://company.zoom.us/j/987654321"
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(now: now, events: [zoomEvent])

        XCTAssertTrue(sections[0].rows[0].hasMeetLink)
        XCTAssertEqual(sections[0].rows[0].platform, .zoom)
    }

    func testMenuBarTitleUsesNextUpcomingTodayEvent() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: date(year: 2026, month: 6, day: 3, hour: 16, minute: 20, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar)
        )

        let title = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .menuBarTitle(now: now, events: [event])

        XCTAssertEqual(title, "Planning in 20 minutes")
    }

    func testMenuBarTitleIgnoresAllDayEventsAndUsesNextTimedEvent() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 30, calendar: calendar)
        let allDayEvent = makeEvent(
            id: "birthday",
            title: "Leona rođendan",
            startDate: date(year: 2026, month: 6, day: 3, hour: 0, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 4, hour: 0, minute: 0, calendar: calendar),
            isAllDay: true
        )
        let timedEvent = makeEvent(
            id: "dinner",
            title: "Leona večera",
            startDate: date(year: 2026, month: 6, day: 3, hour: 19, minute: 30, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 22, minute: 0, calendar: calendar)
        )

        let title = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .menuBarTitle(now: now, events: [allDayEvent, timedEvent])

        XCTAssertEqual(title, "Leona večera in 3 hours")
    }

    func testMenuBarTitleIgnoresTomorrowEvents() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let event = makeEvent(
            id: "event-1",
            title: "Tomorrow planning",
            startDate: date(year: 2026, month: 6, day: 4, hour: 10, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 4, hour: 11, minute: 0, calendar: calendar)
        )

        let title = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .menuBarTitle(now: now, events: [event])

        XCTAssertEqual(title, "Meet")
    }

    func testMenuBarTitleShortensLongEventTitles() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let event = makeEvent(
            id: "event-1",
            title: "1234567890123456789012345",
            startDate: date(year: 2026, month: 6, day: 3, hour: 16, minute: 20, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar)
        )

        let title = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .menuBarTitle(now: now, events: [event])

        XCTAssertEqual(title, "123456789012345678901... in 20 minutes")
    }

    func testHidesFinishedEventsFromSectionsWhenEnabled() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let finishedEvent = makeEvent(
            id: "finished",
            title: "Finished",
            startDate: date(year: 2026, month: 6, day: 3, hour: 14, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 15, minute: 0, calendar: calendar)
        )
        let upcomingEvent = makeEvent(
            id: "upcoming",
            title: "Upcoming",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 0, calendar: calendar)
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(now: now, events: [finishedEvent, upcomingEvent], hideFinishedEvents: true)

        XCTAssertEqual(sections[0].rows.map(\.title), ["Upcoming"])
    }

    func testShowsFinishedEventsFromSectionsWhenDisabled() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let finishedEvent = makeEvent(
            id: "finished",
            title: "Finished",
            startDate: date(year: 2026, month: 6, day: 3, hour: 14, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 15, minute: 0, calendar: calendar)
        )
        let upcomingEvent = makeEvent(
            id: "upcoming",
            title: "Upcoming",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 0, calendar: calendar)
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(now: now, events: [finishedEvent, upcomingEvent], hideFinishedEvents: false)

        XCTAssertEqual(sections[0].rows.map(\.title), ["Finished", "Upcoming"])
    }

    func testRowsCarryAttendeesWithRoomResolutionDisabledByDefault() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 0, calendar: calendar),
            attendees: ["Alice", "MTL-5F-Boardroom"]
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(now: now, events: [event])

        XCTAssertEqual(sections[0].rows[0].attendees, ["Alice", "MTL-5F-Boardroom"])
        XCTAssertNil(sections[0].rows[0].roomName)
    }

    func testRowsResolveRoomWhenConfigEnabled() throws {
        let calendar = fixedCalendar()
        let now = date(year: 2026, month: 6, day: 3, hour: 16, minute: 0, calendar: calendar)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: date(year: 2026, month: 6, day: 3, hour: 17, minute: 0, calendar: calendar),
            endDate: date(year: 2026, month: 6, day: 3, hour: 18, minute: 0, calendar: calendar),
            attendees: ["Alice", "MTL-5F-Boardroom"]
        )

        let sections = CalendarMenuPresenter(calendar: calendar, locale: Locale(identifier: "en_GB"))
            .sections(
                now: now,
                events: [event],
                roomConfig: MeetingRoomConfig(isEnabled: true, isRoomInAttendees: true, pattern: "MTL-*")
            )

        XCTAssertEqual(sections[0].rows[0].roomName, "MTL-5F-Boardroom")
        XCTAssertEqual(sections[0].rows[0].attendees, ["Alice"])
    }

    private func makeEvent(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        notes: String? = nil,
        attendees: [String] = []
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            participationStatus: .accepted,
            url: nil,
            notes: notes,
            location: nil,
            attendees: attendees
        )
    }

    private func fixedCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
