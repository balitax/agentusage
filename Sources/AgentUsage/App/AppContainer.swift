//
//  AppContainer.swift
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

/// Composition root: creates services and builds view models with their dependencies.
final class AppContainer {
    let settings: SettingsService
    let integrations: IntegrationService
    let repository: UsageRepository
    let router: Router
    let app: AppViewModel

    init() {
        settings = SettingsService()
        integrations = IntegrationService()
        repository = UsageRepository(integrations: integrations)
        router = Router(onboarded: settings.onboarded)
        app = AppViewModel(
            router: router, repository: repository, settings: settings, integrations: integrations)
    }

    // MARK: Screens

    func makeOverview() -> OverviewViewModel {
        OverviewViewModel(
            app: app, header: makeHeader(), footer: makeFooter(), chart: UsageChartViewModel(app: app))
    }

    func makeMonthly() -> MonthlyViewModel {
        MonthlyViewModel(app: app, header: makeHeader(), footer: makeFooter())
    }

    func makeAccounts() -> AccountsViewModel {
        AccountsViewModel(
            app: app, footer: makeFooter(),
            fiveHourLimit: LimitStepperViewModel(
                title: "5-hour limit", key: "capFiveHour", defaultValue: 1_500_000, step: 500_000,
                minimum: 500_000, settings: settings, onChange: { [app] in app.objectWillChange.send() }),
            weeklyLimit: LimitStepperViewModel(
                title: "Weekly limit", key: "capSevenDay", defaultValue: 20_000_000, step: 5_000_000,
                minimum: 5_000_000, settings: settings, onChange: { [app] in app.objectWillChange.send() }),
            copilotLimit: LimitStepperViewModel(
                title: "Copilot credits / month", key: "capCopilotCredits", defaultValue: 1_500, step: 500,
                minimum: 500, settings: settings, onChange: { [repository] in repository.refresh() },
                formatter: { Int($0).formatted() }))
    }

    func makeAddIntegration() -> AddIntegrationViewModel {
        AddIntegrationViewModel(app: app, footer: makeFooter())
    }

    func makeOnboarding() -> OnboardingViewModel {
        OnboardingViewModel(app: app)
    }

    // MARK: Shared pieces

    func makeHeader() -> BrandHeaderViewModel { BrandHeaderViewModel(app: app) }
    func makeFooter() -> FooterViewModel { FooterViewModel(app: app) }
}
