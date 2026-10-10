//
//  AppViewModel.swift
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

/// Shared state: account selection, chart range and the menu bar icon values.
final class AppViewModel: BaseViewModel {
    let router: Router
    let repository: UsageRepository
    let settings: SettingsService
    let integrations: IntegrationService

    @Published var selectedID: String?
    @Published var range: UsageRange = .d1

    init(
        router: Router, repository: UsageRepository, settings: SettingsService,
        integrations: IntegrationService
    ) {
        self.router = router
        self.repository = repository
        self.settings = settings
        self.integrations = integrations
        super.init()
        forward(router)
        forward(repository)
        forward(settings)
        forward(integrations)
        store(
            repository.$accounts.sink { [weak self] accounts in
                guard let self else { return }
                if self.selectedID == nil || !accounts.contains(where: { $0.id == self.selectedID }) {
                    self.selectedID = accounts.first?.id
                }
            })
    }

    // MARK: Accounts

    var accounts: [Account] { repository.accounts }
    var loading: Bool { repository.loading }
    var updated: Date { repository.updated }

    var selected: Account {
        accounts.first { $0.id == selectedID } ?? accounts.first
            ?? Account(
                id: "none", name: "No account", email: "Nothing connected", plan: "—", color: LX.accent)
    }

    /// All accounts combined, used by the monthly view.
    var total: Account {
        Account(
            id: "all", name: "All Accounts", email: "", plan: "", color: LX.accent,
            events: accounts.flatMap(\.events).sorted { $0.time < $1.time })
    }

    func select(_ account: Account) {
        selectedID = account.id
        router.go(.overview)
    }

    // MARK: Menu bar

    /// Account whose limits the menu bar icon reflects.
    private var menuBarAccount: Account? {
        if router.screen == .monthly { return total }
        return settings.showHighest ? accounts.max { $0.fiveHour < $1.fiveHour } : selected
    }

    var menuBarFive: Double { menuBarAccount?.fiveHour ?? 0 }
    var menuBarSeven: Double { menuBarAccount?.sevenDay ?? 0 }
    var menuBarPending: Bool { loading || router.screen == .onboarding || accounts.isEmpty }

    // MARK: Onboarding

    var isOnboarding: Bool { !settings.onboarded }

    func finishOnboarding() {
        settings.onboarded = true
        router.onboardingStep = 0
        router.go(.overview)
    }
}
