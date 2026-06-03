import Foundation

public struct AppPreferences: Codable, Equatable {
    public var selectedCalendarIDs: Set<String>?
    public var isOverlayEnabled: Bool
    public var launchAtLogin: Bool
    public var hidesFinishedEvents: Bool

    public init(
        selectedCalendarIDs: Set<String>? = nil,
        isOverlayEnabled: Bool = true,
        launchAtLogin: Bool = false,
        hidesFinishedEvents: Bool = true
    ) {
        self.selectedCalendarIDs = selectedCalendarIDs
        self.isOverlayEnabled = isOverlayEnabled
        self.launchAtLogin = launchAtLogin
        self.hidesFinishedEvents = hidesFinishedEvents
    }

    private enum CodingKeys: String, CodingKey {
        case selectedCalendarIDs
        case isOverlayEnabled
        case launchAtLogin
        case hidesFinishedEvents
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedCalendarIDs = try container.decodeIfPresent(Set<String>.self, forKey: .selectedCalendarIDs)
        isOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .isOverlayEnabled) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        hidesFinishedEvents = try container.decodeIfPresent(Bool.self, forKey: .hidesFinishedEvents) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectedCalendarIDs, forKey: .selectedCalendarIDs)
        try container.encode(isOverlayEnabled, forKey: .isOverlayEnabled)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(hidesFinishedEvents, forKey: .hidesFinishedEvents)
    }
}

public final class AppPreferencesStore {
    private let defaults: UserDefaults
    private let key = "appPreferences"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppPreferences {
        guard let data = defaults.data(forKey: key) else {
            return AppPreferences()
        }

        return (try? JSONDecoder().decode(AppPreferences.self, from: data)) ?? AppPreferences()
    }

    public func save(_ preferences: AppPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}

public enum EventParticipationStatus: Equatable {
    case unknown
    case accepted
    case tentative
    case declined
}

public struct CalendarEventSnapshot: Equatable {
    public let id: String
    public let calendarID: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let participationStatus: EventParticipationStatus
    public let url: URL?
    public let notes: String?
    public let location: String?

    public init(
        id: String,
        calendarID: String = "",
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        participationStatus: EventParticipationStatus,
        url: URL?,
        notes: String?,
        location: String?
    ) {
        self.id = id
        self.calendarID = calendarID
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.participationStatus = participationStatus
        self.url = url
        self.notes = notes
        self.location = location
    }
}

public enum CalendarEventFilter {
    public static func events(
        _ events: [CalendarEventSnapshot],
        selectedCalendarIDs: Set<String>?
    ) -> [CalendarEventSnapshot] {
        guard let selectedCalendarIDs else {
            return events
        }

        return events.filter { selectedCalendarIDs.contains($0.calendarID) }
    }
}

public struct CalendarSnapshot: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let sourceTitle: String?

    public var displayTitle: String {
        guard let sourceTitle, !sourceTitle.isEmpty else {
            return title
        }

        return "\(title) - \(sourceTitle)"
    }

    public init(id: String, title: String, sourceTitle: String? = nil) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
    }
}

public enum CalendarSelectionUpdater {
    public static func updatedSelection(
        currentSelection: Set<String>?,
        allCalendarIDs: Set<String>,
        calendarID: String,
        isSelected: Bool
    ) -> Set<String>? {
        var selection = currentSelection ?? allCalendarIDs

        if isSelected {
            selection.insert(calendarID)
        } else {
            selection.remove(calendarID)
        }

        return selection == allCalendarIDs ? nil : selection
    }
}

public struct JoinableMeeting: Equatable {
    public let eventID: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let meetURL: URL
}

public struct MeetingAlertSelector {
    private let alertLeadTime: TimeInterval
    private let lateAlertGraceTime: TimeInterval

    public init(alertLeadTime: TimeInterval, lateAlertGraceTime: TimeInterval = 120) {
        self.alertLeadTime = alertLeadTime
        self.lateAlertGraceTime = lateAlertGraceTime
    }

    public func meetingToShow(
        now: Date,
        events: [CalendarEventSnapshot],
        suppressedEventIDs: Set<String>
    ) -> JoinableMeeting? {
        events
            .sorted { $0.startDate < $1.startDate }
            .compactMap { event -> JoinableMeeting? in
                guard event.endDate > now else { return nil }
                guard event.startDate <= now.addingTimeInterval(alertLeadTime) else { return nil }
                guard event.startDate >= now.addingTimeInterval(-lateAlertGraceTime) else { return nil }
                guard !event.isAllDay else { return nil }
                guard event.participationStatus != .declined else { return nil }
                guard !suppressedEventIDs.contains(event.id) else { return nil }

                let candidates = [event.url?.absoluteString, event.notes, event.location, event.title].compactMap { $0 }
                guard let meetURL = GoogleMeetLinkFinder.firstLink(in: candidates) else { return nil }

                return JoinableMeeting(
                    eventID: event.id,
                    title: event.title,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    meetURL: meetURL
                )
            }
            .first
    }
}

public struct CalendarMenuSection: Equatable {
    public let title: String
    public let rows: [CalendarMenuRow]
}

public struct CalendarMenuRow: Equatable {
    public let eventID: String
    public let title: String
    public let timeText: String
    public let hasMeetLink: Bool
    public let meetURL: URL?
}

public struct CalendarMenuPresenter {
    private let calendar: Calendar
    private let timeFormatter: DateFormatter
    private let menuBarTitleLimit = 24

    public init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar

        let timeFormatter = DateFormatter()
        timeFormatter.calendar = calendar
        timeFormatter.timeZone = calendar.timeZone
        timeFormatter.locale = locale
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        self.timeFormatter = timeFormatter
    }

    public func sections(
        now: Date,
        events: [CalendarEventSnapshot],
        hideFinishedEvents: Bool = true
    ) -> [CalendarMenuSection] {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let visibleEvents = hideFinishedEvents ? events.filter { $0.endDate > now } : events

        return [
            section(title: "Today's Events", day: now, events: visibleEvents),
            section(title: "Tomorrow's Events", day: tomorrow, events: visibleEvents)
        ].compactMap { section in
            section.rows.isEmpty ? nil : section
        }
    }

    public func menuBarTitle(now: Date, events: [CalendarEventSnapshot]) -> String {
        guard let event = events
            .filter({ calendar.isDate($0.startDate, inSameDayAs: now) })
            .filter({ !$0.isAllDay })
            .filter({ $0.endDate > now })
            .sorted(by: { $0.startDate < $1.startDate })
            .first else {
            return "Meet"
        }

        let secondsUntilStart = Int(event.startDate.timeIntervalSince(now).rounded(.up))

        if secondsUntilStart <= 0 {
            return "\(shortTitle(event.title)) now"
        }

        let minutesUntilStart = max(1, Int(ceil(Double(secondsUntilStart) / 60)))
        if minutesUntilStart >= 120 {
            let hoursUntilStart = minutesUntilStart / 60
            return "\(shortTitle(event.title)) in \(hoursUntilStart) hours"
        }

        return "\(shortTitle(event.title)) in \(minutesUntilStart) \(minutesUntilStart == 1 ? "minute" : "minutes")"
    }

    private func shortTitle(_ title: String) -> String {
        guard title.count > menuBarTitleLimit else {
            return title
        }

        return "\(title.prefix(menuBarTitleLimit - 3))..."
    }

    private func section(title: String, day: Date, events: [CalendarEventSnapshot]) -> CalendarMenuSection {
        let rows = events
            .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
            .map(row)

        return CalendarMenuSection(title: title, rows: rows)
    }

    private func row(for event: CalendarEventSnapshot) -> CalendarMenuRow {
        let meetURL = GoogleMeetLinkFinder.firstLink(in: [event.url?.absoluteString, event.notes, event.location, event.title].compactMap { $0 })

        return CalendarMenuRow(
            eventID: event.id,
            title: event.title,
            timeText: event.isAllDay ? "All-day" : timeFormatter.string(from: event.startDate),
            hasMeetLink: meetURL != nil,
            meetURL: meetURL
        )
    }
}

public enum MeetingCountdownFormatter {
    public static func text(now: Date, startDate: Date) -> String {
        let seconds = Int(startDate.timeIntervalSince(now).rounded(.up))

        if seconds < 0 {
            let elapsedSeconds = abs(seconds)

            if elapsedSeconds < 60 {
                return "Started just now"
            }

            let elapsedMinutes = Int(ceil(Double(elapsedSeconds) / 60))
            return "Started \(elapsedMinutes) \(elapsedMinutes == 1 ? "minute" : "minutes") ago"
        }

        if seconds == 0 {
            return "Starts now"
        }

        if seconds < 60 {
            return "Starts in \(seconds) seconds"
        }

        let minutes = Int(ceil(Double(seconds) / 60))
        return "Starts in \(minutes) \(minutes == 1 ? "minute" : "minutes")"
    }
}

public enum GoogleMeetLinkFinder {
    public static func firstLink(in candidates: [String]) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }

        for candidate in candidates {
            let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
            let matches = detector.matches(in: candidate, options: [], range: range)

            for match in matches {
                guard let url = match.url, isGoogleMeetURL(url) else { continue }
                return url
            }
        }

        return nil
    }

    private static func isGoogleMeetURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return false
        }

        return url.host?.lowercased() == "meet.google.com"
    }
}
