//
//  AccountTests.swift
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

final class AccountTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "capFiveHour")
        UserDefaults.standard.removeObject(forKey: "capSevenDay")
    }

    func testRemoteUtilizationOverridesLocalCalculation() {
        let a = TestSupport.account(
            events: [TestSupport.event(minutesAgo: 10, tokens: 1_000_000)], remoteFive: 40, remoteSeven: 25)
        XCTAssertEqual(a.fiveHour, 0.40, accuracy: 0.0001)
        XCTAssertEqual(a.sevenDay, 0.25, accuracy: 0.0001)
    }

    func testFiveHourUsesActiveWindowAndConfiguredLimit() {
        let a = TestSupport.account(events: [TestSupport.event(minutesAgo: 60, tokens: 750_000)])
        XCTAssertNotNil(a.activeWindowEnd)
        XCTAssertEqual(a.fiveHour, 0.5, accuracy: 0.0001)  // 750K of the 1.5M default
    }

    func testNoActiveWindowAfterFiveHours() {
        let a = TestSupport.account(events: [TestSupport.event(minutesAgo: 6 * 60, tokens: 500)])
        XCTAssertNil(a.activeWindowEnd)
        XCTAssertEqual(a.fiveHour, 0)
    }

    func testNearLimit() {
        XCTAssertTrue(TestSupport.account(remoteFive: 85).nearLimit)
        XCTAssertFalse(TestSupport.account(remoteFive: 50).nearLimit)
    }

    func testTimeBucketsCoverRangeAndConserveTokens() {
        let a = TestSupport.account(events: [
            TestSupport.event(minutesAgo: 30, tokens: 100), TestSupport.event(minutesAgo: 600, tokens: 50),
            TestSupport.event(minutesAgo: 3 * 24 * 60, tokens: 999),
        ])
        let day = a.timeBuckets(.d1)
        XCTAssertEqual(day.count, 32)
        XCTAssertEqual(day.map(\.tokens).reduce(0, +), 150)
        XCTAssertEqual(a.timeBuckets(.h1).map(\.tokens).reduce(0, +), 100)
        XCTAssertEqual(a.series(.d7).reduce(0, +), 1_149)
    }

    func testMonthlyTotalsReturnsRequestedNumberOfMonths() {
        let a = TestSupport.account(events: [TestSupport.event(minutesAgo: 1, tokens: 400)])
        let months = a.monthlyTotals(6)
        XCTAssertEqual(months.count, 6)
        XCTAssertEqual(months.last?.1 ?? 0, a.month, accuracy: 0.001)
    }

    func testInitialIsUppercased() {
        XCTAssertEqual(TestSupport.account("work").initial, "W")
    }

    func testCreditUsage() {
        let c = CreditUsage(used: 420, allowance: 1_500, resets: Date(), models: [])
        XCTAssertEqual(c.fraction, 0.28, accuracy: 0.0001)
        XCTAssertEqual(CreditUsage(used: 5, allowance: 0, resets: Date(), models: []).fraction, 0)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let reset = CreditUsage.nextReset
        XCTAssertGreaterThan(reset, Date())
        XCTAssertEqual(cal.component(.day, from: reset), 1)
        XCTAssertEqual(cal.component(.hour, from: reset), 0)
    }
}
