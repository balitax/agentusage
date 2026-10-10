//
//  AccountsAndOnboardingTests.swift
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

final class AccountsAndOnboardingTests: XCTestCase {
    private func makeAccounts(_ env: TestSupport.Environment) -> AccountsViewModel {
        let s = env.settings
        return AccountsViewModel(
            app: env.app, footer: FooterViewModel(app: env.app),
            fiveHourLimit: LimitStepperViewModel(
                title: "5h", key: "five", defaultValue: 1_500_000, step: 500_000, minimum: 500_000,
                settings: s),
            weeklyLimit: LimitStepperViewModel(
                title: "7d", key: "week", defaultValue: 20_000_000, step: 5_000_000, minimum: 5_000_000,
                settings: s),
            copilotLimit: LimitStepperViewModel(
                title: "Copilot", key: "copilot", defaultValue: 1_500, step: 500, minimum: 500, settings: s))
    }

    // MARK: Accounts

    func testAccountsMenuBarPreference() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()])
        let vm = makeAccounts(env)
        XCTAssertEqual(vm.menuBarSubtitle, "Follows the selected account")
        vm.showHighest = true
        XCTAssertTrue(env.settings.showHighest)
        XCTAssertEqual(vm.menuBarSubtitle, "Highest usage across all accounts")
    }

    func testAccountsDetectsCopilot() async {
        let env = await TestSupport.environment(accounts: [
            TestSupport.account("Claude"),
            TestSupport.account("GitHub", integrationID: "x", provider: .copilot),
        ])
        XCTAssertTrue(makeAccounts(env).hasCopilot)
    }

    func testHidingLocalAccountIsReversible() async {
        let local = TestSupport.account("Local")
        let env = await TestSupport.environment(accounts: [local])
        let vm = makeAccounts(env)
        XCTAssertEqual(vm.hiddenCount, 0)
        vm.remove(local)
        XCTAssertEqual(vm.hiddenCount, 1)
        XCTAssertEqual(vm.restoreTitle, "Restore 1 hidden source")
        vm.restoreHidden()
        XCTAssertEqual(vm.hiddenCount, 0)
    }

    func testEditNavigatesOnlyForIntegrations() async {
        let linked = TestSupport.account("Linked", integrationID: "abc")
        let env = await TestSupport.environment(accounts: [linked, TestSupport.account("Local")])
        let vm = makeAccounts(env)
        vm.edit(env.app.accounts[1])
        XCTAssertEqual(env.router.screen, .overview)
        vm.edit(linked)
        XCTAssertEqual(env.router.screen, .addIntegration)
        XCTAssertEqual(env.router.editingID, "abc")
    }

    // MARK: Limit stepper

    func testLimitStepperClampsAndPersists() {
        let settings = SettingsService(defaults: TestSupport.defaults())
        var changes = 0
        let vm = LimitStepperViewModel(
            title: "t", key: "k", defaultValue: 1_000_000, step: 500_000, minimum: 500_000,
            settings: settings,
            onChange: { changes += 1 })
        XCTAssertEqual(vm.text, "1.0M")
        vm.decrease()
        vm.decrease()
        vm.decrease()
        XCTAssertEqual(vm.value, 500_000)
        vm.increase()
        XCTAssertEqual(vm.value, 1_000_000)
        XCTAssertEqual(settings.value(forKey: "k", default: 0), 1_000_000)
        XCTAssertEqual(changes, 4)
    }

    // MARK: Onboarding

    func testOnboardingWithLocalLogsSkipsToReady() async {
        let env = await TestSupport.environment(accounts: [TestSupport.account()], onboarded: false)
        let vm = OnboardingViewModel(app: env.app)
        XCTAssertTrue(vm.localFound)
        XCTAssertTrue(vm.useLocal)
        vm.start()
        XCTAssertEqual(vm.step, 1)
        vm.continueFromSource()
        XCTAssertEqual(vm.step, 2)
        XCTAssertEqual(vm.readySubtitle, "Reading usage from 1 source. Refreshes every minute.")
        vm.finish()
        XCTAssertTrue(env.settings.onboarded)
        XCTAssertEqual(env.router.screen, .overview)
    }

    func testOnboardingWithoutLocalLogsOpensAddIntegration() async {
        let env = await TestSupport.environment(accounts: [], onboarded: false)
        let vm = OnboardingViewModel(app: env.app)
        XCTAssertFalse(vm.localFound)
        vm.continueFromSource()
        XCTAssertEqual(env.router.screen, .addIntegration)
        XCTAssertEqual(vm.readySubtitle, "Reading usage from 0 sources. Refreshes every minute.")
    }

    // MARK: Add integration

    func testAddIntegrationFormRules() async {
        let env = await TestSupport.environment(accounts: [])
        let vm = AddIntegrationViewModel(app: env.app, footer: FooterViewModel(app: env.app))
        XCTAssertEqual(vm.title, "Add integration")
        XCTAssertTrue(vm.usesOAuth)
        XCTAssertEqual(vm.buttonTitle, "Sign in with Claude")
        XCTAssertTrue(vm.canSubmit)
        XCTAssertFalse(vm.showsTokenField)

        vm.select(.codex)
        XCTAssertFalse(vm.usesOAuth)
        XCTAssertTrue(vm.showsTokenField)
        XCTAssertEqual(vm.buttonTitle, "Connect")
        XCTAssertFalse(vm.canSubmit)
        vm.token = "sk-admin-123"
        XCTAssertTrue(vm.canSubmit)
        XCTAssertTrue(vm.isEnabled(.copilot))
        XCTAssertFalse(vm.isEnabled(.gemini))
    }
}
