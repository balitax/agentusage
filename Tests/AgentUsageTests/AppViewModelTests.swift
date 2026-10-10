//
//  AppViewModelTests.swift
//  AgentUsage
//
//  Author: Agus Cahyono
//  License: MIT
//
//  Copyright (c) 2026 Agus Cahyono
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest

@testable import AgentUsage

final class AppViewModelTests: XCTestCase {
    func testSelectsFirstAccountByDefault() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("Personal"), TestSupport.account("Work"),
        ])
        XCTAssertEqual(env.app.selected.name, "Personal")
    }

    func testSelectChangesAccountAndNavigatesToOverview() async {
        let work = TestSupport.account("Work")
        let env = await TestSupport.environment(accounts: [TestSupport.account("Personal"), work])
        env.router.go(.accounts)
        env.app.select(work)
        XCTAssertEqual(env.app.selected.name, "Work")
        XCTAssertEqual(env.router.screen, .overview)
    }

    func testEmptyStateUsesPlaceholderAccount() async {
        let env = await TestSupport.environment(accounts: [])
        XCTAssertEqual(env.app.selected.name, "No account")
        XCTAssertTrue(env.app.menuBarPending)
    }

    func testMenuBarFollowsSelectedAccountByDefault() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("Personal", remoteFive: 20, remoteSeven: 10),
            TestSupport.account("Work", remoteFive: 80, remoteSeven: 60),
        ])
        XCTAssertEqual(env.app.menuBarFive, 0.2, accuracy: 0.001)
        XCTAssertEqual(env.app.menuBarSeven, 0.1, accuracy: 0.001)
        XCTAssertFalse(env.app.menuBarPending)
    }

    func testMenuBarShowsHighestWhenEnabled() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("Personal", remoteFive: 20, remoteSeven: 10),
            TestSupport.account("Work", remoteFive: 80, remoteSeven: 60),
        ])
        env.settings.showHighest = true
        XCTAssertEqual(env.app.menuBarFive, 0.8, accuracy: 0.001)
        XCTAssertEqual(env.app.menuBarSeven, 0.6, accuracy: 0.001)
    }

    func testMenuBarIsPendingDuringOnboarding() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()], onboarded: false)
        XCTAssertTrue(env.app.menuBarPending)
        XCTAssertTrue(env.app.isOnboarding)
        env.app.finishOnboarding()
        XCTAssertFalse(env.app.isOnboarding)
        XCTAssertEqual(env.router.screen, .overview)
    }

    func testTotalCombinesEventsOfAllAccounts() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("A", events: [TestSupport.event(minutesAgo: 5, tokens: 100)]),
            TestSupport.account("B", events: [TestSupport.event(minutesAgo: 1, tokens: 50)]),
        ])
        XCTAssertEqual(env.app.total.events.count, 2)
        XCTAssertEqual(env.app.total.events.map(\.tokens), [100, 50])
    }
}
