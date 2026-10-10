//
//  AccountsViewModel.swift
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

import Foundation

/// Account list, menu bar preference and usage limits.
final class AccountsViewModel: BaseViewModel {
    private let app: AppViewModel
    let footer: FooterViewModel
    let fiveHourLimit: LimitStepperViewModel
    let weeklyLimit: LimitStepperViewModel
    let copilotLimit: LimitStepperViewModel

    init(
        app: AppViewModel, footer: FooterViewModel, fiveHourLimit: LimitStepperViewModel,
        weeklyLimit: LimitStepperViewModel, copilotLimit: LimitStepperViewModel
    ) {
        self.app = app
        self.footer = footer
        self.fiveHourLimit = fiveHourLimit
        self.weeklyLimit = weeklyLimit
        self.copilotLimit = copilotLimit
        super.init()
        forward(app)
    }

    var accounts: [Account] { app.accounts }
    var hasCopilot: Bool { accounts.contains { $0.provider == .copilot } }
    var hiddenCount: Int { app.integrations.hiddenLocal.count }

    var restoreTitle: String {
        "Restore \(hiddenCount) hidden source\(hiddenCount == 1 ? "" : "s")"
    }

    var showHighest: Bool {
        get { app.settings.showHighest }
        set { app.settings.showHighest = newValue }
    }

    var menuBarSubtitle: String {
        showHighest ? "Highest usage across all accounts" : "Follows the selected account"
    }

    func isActive(_ account: Account) -> Bool { account.id == app.selected.id }
    func select(_ account: Account) { app.select(account) }
    func edit(_ account: Account) { account.integrationID.map { app.router.edit($0) } }
    func remove(_ account: Account) { app.integrations.remove(account) }
    func add() { app.router.addIntegration() }
    func restoreHidden() { app.integrations.restoreHidden() }
}
