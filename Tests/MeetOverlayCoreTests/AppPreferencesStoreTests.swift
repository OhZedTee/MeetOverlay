import XCTest
@testable import MeetOverlayCore

final class AppPreferencesStoreTests: XCTestCase {
    func testLoadsDefaultsWhenNothingWasSaved() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)

        let preferences = store.load()

        XCTAssertNil(preferences.selectedCalendarIDs)
        XCTAssertTrue(preferences.isOverlayEnabled)
        XCTAssertFalse(preferences.launchAtLogin)
        XCTAssertTrue(preferences.hidesFinishedEvents)
        XCTAssertEqual(preferences.alertLeadTime, 900)
        XCTAssertEqual(preferences.alertLeadTimeUnit, .minutes)
        XCTAssertTrue(preferences.isSnoozeEnabled)
        XCTAssertEqual(preferences.snoozeOptions, [60, 120, 300, 600, 900])
    }

    func testPersistsPreferences() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)
        let savedPreferences = AppPreferences(
            selectedCalendarIDs: ["work", "personal"],
            isOverlayEnabled: false,
            launchAtLogin: true,
            hidesFinishedEvents: false,
            alertLeadTime: 300,
            alertLeadTimeUnit: .seconds,
            isSnoozeEnabled: false,
            snoozeOptions: [30, 60]
        )

        store.save(savedPreferences)

        XCTAssertEqual(store.load(), savedPreferences)
    }

    func testLoadsOldSavedPreferencesWithHideFinishedEventsEnabled() throws {
        let defaults = makeDefaults()
        let oldSavedPreferences = """
        {
          "selectedCalendarIDs": ["work"],
          "isOverlayEnabled": false,
          "launchAtLogin": true
        }
        """.data(using: .utf8)!
        defaults.set(oldSavedPreferences, forKey: "appPreferences")

        let preferences = AppPreferencesStore(defaults: defaults).load()

        XCTAssertEqual(preferences.selectedCalendarIDs, ["work"])
        XCTAssertFalse(preferences.isOverlayEnabled)
        XCTAssertTrue(preferences.launchAtLogin)
        XCTAssertTrue(preferences.hidesFinishedEvents)
        XCTAssertEqual(preferences.alertLeadTime, 900, "Old saved data missing alertLeadTime should default to 15 minutes")
        XCTAssertEqual(preferences.alertLeadTimeUnit, .minutes, "Old saved data missing alertLeadTimeUnit should default to minutes")
        XCTAssertTrue(preferences.isSnoozeEnabled, "Old saved data missing isSnoozeEnabled should default to true")
        XCTAssertEqual(preferences.snoozeOptions, [60, 120, 300, 600, 900], "Old saved data missing snoozeOptions should use defaults")
    }

    func testPersistsAlertLeadTime() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)

        store.save(AppPreferences(alertLeadTime: 600))

        XCTAssertEqual(store.load().alertLeadTime, 600)
    }

    func testPersistsSnoozeSettings() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)

        store.save(AppPreferences(
            alertLeadTimeUnit: .seconds,
            isSnoozeEnabled: false,
            snoozeOptions: [30, 90, 180]
        ))

        let loaded = store.load()
        XCTAssertEqual(loaded.alertLeadTimeUnit, .seconds)
        XCTAssertFalse(loaded.isSnoozeEnabled)
        XCTAssertEqual(loaded.snoozeOptions, [30, 90, 180])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MeetOverlayTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
