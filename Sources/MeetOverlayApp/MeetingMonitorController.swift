import AppKit
import Foundation
import MeetOverlayCore

@MainActor
final class MeetingMonitorController {
    private let calendarEventSource: CalendarEventSource
    private let overlayPresenter: OverlayPresenter
    private let statusMenu: StatusMenuController
    private let preferencesStore: AppPreferencesStore
    private let menuPresenter = CalendarMenuPresenter()

    private var timer: Timer?
    private var isEnabled = true
    private var hasCalendarAccess = false
    private var visibleEventID: String?
    private var suppressedEventIDs = Set<String>()
    private var snoozedUntil: [String: Date] = [:]

    init(
        calendarEventSource: CalendarEventSource,
        overlayPresenter: OverlayPresenter,
        statusMenu: StatusMenuController,
        preferencesStore: AppPreferencesStore
    ) {
        self.calendarEventSource = calendarEventSource
        self.overlayPresenter = overlayPresenter
        self.statusMenu = statusMenu
        self.preferencesStore = preferencesStore
        self.isEnabled = preferencesStore.load().isOverlayEnabled

        statusMenu.onOpenCalendarSettings = {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
            NSWorkspace.shared.open(url)
        }
    }

    func start() {
        statusMenu.update(status: "Requesting Calendar access", isEnabled: isEnabled)

        calendarEventSource.requestAccess { [weak self] granted in
            guard let self else { return }

            self.hasCalendarAccess = granted

            if granted {
                self.statusMenu.update(status: "Watching for meetings", isEnabled: self.isEnabled)
                self.startTimer()
                self.checkNow()
            } else {
                self.statusMenu.update(status: "Calendar access denied", isEnabled: self.isEnabled)
            }
        }
    }

    func refreshFromPreferences() {
        isEnabled = preferencesStore.load().isOverlayEnabled
        checkNow()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkNow()
            }
        }
    }

    private func checkNow() {
        guard hasCalendarAccess else {
            statusMenu.update(
                status: "Calendar access needed",
                isEnabled: isEnabled,
                emptyMessage: "Allow Calendar access in System Settings",
                showsCalendarSettingsAction: true
            )
            return
        }

        let now = Date()
        let preferences = preferencesStore.load()
        isEnabled = preferences.isOverlayEnabled
        let events = eventsForMenu(now: now, preferences: preferences)
        let sections = menuPresenter.sections(
            now: now,
            events: events,
            hideFinishedEvents: preferences.hidesFinishedEvents,
            roomConfig: preferences.meetingRoomConfig
        )
        let menuBarTitle = menuPresenter.menuBarTitle(now: now, events: events)
        let emptyMessage = emptyMessage(for: preferences)

        guard isEnabled else {
            visibleEventID = nil
            overlayPresenter.hide()
            statusMenu.update(
                status: "Fullscreen alerts off",
                isEnabled: isEnabled,
                menuBarTitle: menuBarTitle,
                sections: sections,
                emptyMessage: emptyMessage
            )
            return
        }

        let activelySnoozed = Set(snoozedUntil.filter { $0.value > now }.keys)
        let selector = MeetingAlertSelector(alertLeadTime: preferences.alertLeadTime)
        let meeting = selector.meetingToShow(now: now, events: events, suppressedEventIDs: suppressedEventIDs.union(activelySnoozed))

        guard let meeting else {
            visibleEventID = nil
            overlayPresenter.hide()
            statusMenu.update(
                status: "No meeting soon",
                isEnabled: isEnabled,
                menuBarTitle: menuBarTitle,
                sections: sections,
                emptyMessage: emptyMessage
            )
            return
        }

        statusMenu.update(
            status: "Upcoming: \(meeting.title)",
            isEnabled: isEnabled,
            menuBarTitle: menuBarTitle,
            sections: sections,
            emptyMessage: emptyMessage
        )

        guard visibleEventID != meeting.eventID else {
            return
        }

        visibleEventID = meeting.eventID
        let roomPresentation = MeetingRoomResolver.resolve(
            attendees: meeting.attendees,
            location: meeting.location,
            config: preferences.meetingRoomConfig
        )
        overlayPresenter.show(
            meeting: meeting,
            onJoin: { [weak self] in
                NSWorkspace.shared.open(meeting.meetURL)
                self?.suppressVisibleMeeting(meeting.eventID)
            },
            onDismiss: { [weak self] in
                self?.suppressVisibleMeeting(meeting.eventID)
            },
            onSnooze: { [weak self] duration in
                self?.snoozeVisibleMeeting(meeting.eventID, duration: duration)
            },
            snoozeOptions: preferences.isSnoozeEnabled ? preferences.snoozeOptions.sorted() : [],
            attendees: roomPresentation.attendees,
            roomName: roomPresentation.roomName
        )
    }

    private func eventsForMenu(now: Date, preferences: AppPreferences) -> [CalendarEventSnapshot] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 2, to: startDate) ?? now.addingTimeInterval(48 * 60 * 60)
        let events = calendarEventSource.events(from: startDate, to: endDate)

        return CalendarEventFilter.events(events, selectedCalendarIDs: preferences.selectedCalendarIDs)
    }

    private func emptyMessage(for preferences: AppPreferences) -> String {
        if preferences.selectedCalendarIDs == [] {
            return "No calendars selected. Open Settings to choose calendars."
        }

        return "No selected-calendar events today or tomorrow"
    }

    private func suppressVisibleMeeting(_ eventID: String) {
        suppressedEventIDs.insert(eventID)
        visibleEventID = nil
        overlayPresenter.hide()
        checkNow()
    }

    private func snoozeVisibleMeeting(_ eventID: String, duration: TimeInterval) {
        snoozedUntil[eventID] = Date().addingTimeInterval(duration)
        visibleEventID = nil
        overlayPresenter.hide()
        checkNow()
    }
}
