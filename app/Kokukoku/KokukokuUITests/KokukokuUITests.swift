//
//  KokukokuUITests.swift
//  KokukokuUITests
//
//  Created by uto note on 2026/02/24.
//

import XCTest

final class KokukokuUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testExample() {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Timer flow (Start → Pause → Resume → Reset)

    #if os(macOS)
        /// Verify the complete timer lifecycle through the main window.
        ///
        /// This test exercises the shared `TimerStore` that backs both the main window
        /// and the MenuBarExtra panel. Since both scenes bind to the same `@Observable`
        /// store instance (see `KokukokuApp.body`), proving the main-window flow is
        /// correct also proves that MenuBarExtra reflects the same state.
        ///
        /// Direct MenuBarExtra panel interaction is not tested here because XCUITest
        /// cannot reliably click macOS status-bar items to open the `.window`-style panel.
        @MainActor
        func testTimerStartPauseResumeReset() {
            let app = XCUIApplication()
            app.launch()

            // --- Idle state ---
            let primaryAction = app.buttons["timer.primaryAction"]
            guard primaryAction.waitForExistence(timeout: 10) else {
                XCTFail("timer.primaryAction button not found after launch")
                return
            }
            XCTAssertEqual(primaryAction.label, "Start")

            let resetButton = app.buttons["timer.reset"]
            XCTAssertTrue(resetButton.exists)
            XCTAssertFalse(resetButton.isEnabled, "Reset should be disabled in idle state")

            // --- Start (idle → running) ---
            primaryAction.click()
            let pausePredicate = NSPredicate(format: "label == 'Pause'")
            expectation(for: pausePredicate, evaluatedWith: primaryAction)
            waitForExpectations(timeout: 3)
            XCTAssertTrue(resetButton.isEnabled, "Reset should be enabled while running")

            // --- Pause (running → paused) ---
            primaryAction.click()
            let resumePredicate = NSPredicate(format: "label == 'Resume'")
            expectation(for: resumePredicate, evaluatedWith: primaryAction)
            waitForExpectations(timeout: 3)
            XCTAssertTrue(resetButton.isEnabled, "Reset should be enabled while paused")

            // --- Resume (paused → running) ---
            primaryAction.click()
            expectation(for: pausePredicate, evaluatedWith: primaryAction)
            waitForExpectations(timeout: 3)

            // --- Pause again, then Reset ---
            primaryAction.click()
            expectation(for: resumePredicate, evaluatedWith: primaryAction)
            waitForExpectations(timeout: 3)

            resetButton.click()
            let startPredicate = NSPredicate(format: "label == 'Start'")
            expectation(for: startPredicate, evaluatedWith: primaryAction)
            waitForExpectations(timeout: 3)
            XCTAssertFalse(resetButton.isEnabled, "Reset should be disabled after reset")
        }

        /// Verify the MenuBarExtra status item exists in the accessibility tree.
        ///
        /// Note: XCUITest cannot reliably open the `.window`-style MenuBarExtra panel
        /// (status items are "not hittable"), so we only verify the item exists.
        /// Full MenuBarExtra interaction is verified manually.
        @MainActor
        func testMenuBarExtraStatusItemExists() {
            let app = XCUIApplication()
            app.launch()

            let statusItem = app.menuBars.children(matching: .statusItem).firstMatch
            XCTAssertTrue(
                statusItem.waitForExistence(timeout: 5),
                "MenuBarExtra status item should exist after launch"
            )
        }
    #endif
}
