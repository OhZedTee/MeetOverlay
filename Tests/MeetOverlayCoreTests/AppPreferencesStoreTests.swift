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
    }

    func testPersistsPreferences() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)
        let savedPreferences = AppPreferences(
            selectedCalendarIDs: ["work", "personal"],
            isOverlayEnabled: false,
            launchAtLogin: true,
            hidesFinishedEvents: false
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
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MeetOverlayTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
