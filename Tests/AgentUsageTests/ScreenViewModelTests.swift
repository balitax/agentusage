//
//  ScreenViewModelTests.swift
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

final class ScreenViewModelTests: XCTestCase {
    // MARK: Brand header

    func testHeaderShowsFirstNameAndInitial() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account("Agus Cahyono")])
        let header = BrandHeaderViewModel(app: env.app)
        XCTAssertEqual(header.title, "Agus")
        XCTAssertEqual(header.letter, "A")
        XCTAssertFalse(header.canShowAll)
    }

    func testHeaderOnMonthlyScreenShowsAllAccounts() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("A"), TestSupport.account("B"),
        ])
        env.router.go(.monthly)
        let header = BrandHeaderViewModel(app: env.app)
        XCTAssertEqual(header.title, "All Accounts")
        XCTAssertEqual(header.letter, "∑")
        XCTAssertTrue(header.canShowAll)
        XCTAssertFalse(header.isSelected(env.app.accounts[0]))
    }

    // MARK: Chart

    func testChartHoverIsClampedToBucketRange() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()])
        let chart = UsageChartViewModel(app: env.app)
        XCTAssertNil(chart.tooltip)
        chart.hover(fraction: 5)
        XCTAssertEqual(chart.hovered, 31)
        chart.hover(fraction: -1)
        XCTAssertEqual(chart.hovered, 0)
        chart.endHover()
        XCTAssertNil(chart.hovered)
    }

    func testChartTooltipDescribesHoveredBar() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account(events: [TestSupport.event(minutesAgo: 0, tokens: 100)])
        ])
        let chart = UsageChartViewModel(app: env.app)
        chart.hover(fraction: 0.999)
        XCTAssertEqual(chart.tooltip?.value, "100 tokens")
        XCTAssertTrue(chart.tooltip?.lines.contains("100% of range total") ?? false)
        chart.hover(fraction: 0)
        XCTAssertEqual(chart.tooltip?.lines, ["No activity"])
    }

    func testChartOpacityHighlightsHoveredBar() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()])
        let chart = UsageChartViewModel(app: env.app)
        XCTAssertEqual(chart.opacity(at: 31, count: 32), 1)
        XCTAssertEqual(chart.opacity(at: 0, count: 32), 0.5)
        chart.hover(fraction: 0)
        XCTAssertEqual(chart.opacity(at: 0, count: 32), 1)
        XCTAssertEqual(chart.opacity(at: 5, count: 32), 0.3)
    }

    // MARK: Overview

    func testOverviewRangeIndexUpdatesSharedRange() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account(remoteFive: 42, remoteSeven: 27)
        ])
        let vm = OverviewViewModel(
            app: env.app, header: BrandHeaderViewModel(app: env.app), footer: FooterViewModel(app: env.app),
            chart: UsageChartViewModel(app: env.app))
        XCTAssertEqual(vm.fiveHour, 0.42, accuracy: 0.001)
        XCTAssertEqual(vm.sevenDay, 0.27, accuracy: 0.001)
        XCTAssertEqual(vm.rangeItems, ["1h", "6h", "1d", "7d", "30d"])
        vm.rangeIndex = 3
        XCTAssertEqual(env.app.range, .d7)
        XCTAssertNil(vm.credits)
    }

    // MARK: Monthly

    func testMonthlyWithoutHistory() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()])
        let vm = MonthlyViewModel(
            app: env.app, header: BrandHeaderViewModel(app: env.app), footer: FooterViewModel(app: env.app))
        XCTAssertEqual(vm.months.count, 6)
        XCTAssertEqual(vm.projectionText, "No earlier data")
        XCTAssertEqual(vm.totalText, "0")
    }

    func testMonthlySharesAddUp() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("A", events: [TestSupport.event(minutesAgo: 1, tokens: 300)]),
            TestSupport.account("B", events: [TestSupport.event(minutesAgo: 1, tokens: 100)]),
        ])
        let vm = MonthlyViewModel(
            app: env.app, header: BrandHeaderViewModel(app: env.app), footer: FooterViewModel(app: env.app))
        XCTAssertEqual(vm.shares.map(\.percent), ["75%", "25%"])
        XCTAssertEqual(vm.totalText, "400")
    }

    func testMonthlyTabsReturnToOverview() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()])
        env.router.go(.monthly)
        let vm = MonthlyViewModel(
            app: env.app, header: BrandHeaderViewModel(app: env.app), footer: FooterViewModel(app: env.app))
        XCTAssertEqual(vm.viewIndex, 1)
        vm.viewIndex = 0
        XCTAssertEqual(env.router.screen, .overview)
    }

    func testMonthlyHoverTooltipMarksCurrentMonth() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()])
        let vm = MonthlyViewModel(
            app: env.app, header: BrandHeaderViewModel(app: env.app), footer: FooterViewModel(app: env.app))
        XCTAssertNil(vm.tooltip)
        vm.hover(fraction: 0.99)
        XCTAssertTrue(vm.tooltip?.title.hasSuffix("(so far)") ?? false)
        vm.endHover()
        XCTAssertNil(vm.tooltip)
    }
}
