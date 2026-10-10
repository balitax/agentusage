//
//  TestSupport.swift
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

import SwiftUI
import XCTest

@testable import AgentUsage

/// Shared helpers that build isolated app state without touching the real preferences or network.
enum TestSupport {
    static func defaults() -> UserDefaults {
        let name = "AgentUsageTests.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    static func account(
        _ name: String = "Personal", email: String = "a@example.com", events: [UsageEvent] = [],
        remoteFive: Double? = nil, remoteSeven: Double? = nil, integrationID: String? = nil,
        provider: ProviderKind = .claude
    ) -> Account {
        var a = Account(id: name, name: name, email: email, plan: "PRO", color: .green)
        a.events = events
        a.integrationID = integrationID
        a.provider = provider
        if remoteFive != nil || remoteSeven != nil {
            a.remote = RemoteUsage(fiveHour: remoteFive, sevenDay: remoteSeven)
        }
        return a
    }

    static func event(minutesAgo: Double, tokens: Int) -> UsageEvent {
        UsageEvent(time: Date().addingTimeInterval(-minutesAgo * 60), tokens: tokens)
    }

    struct Environment {
        let settings: SettingsService
        let integrations: IntegrationService
        let repository: UsageRepository
        let router: Router
        let app: AppViewModel
    }

    /// Builds the object graph with a stubbed account loader.
    static func environment(accounts: [Account], onboarded: Bool = true) async -> Environment {
        let d = defaults()
        let settings = SettingsService(defaults: d)
        settings.onboarded = onboarded
        let integrations = IntegrationService(defaults: d)
        let repository = UsageRepository(
            integrations: integrations, load: { _, _ in accounts }, autoRefresh: false)
        await repository.reload()
        let router = Router(onboarded: onboarded)
        let app = AppViewModel(
            router: router, repository: repository, settings: settings, integrations: integrations)
        return Environment(
            settings: settings, integrations: integrations, repository: repository, router: router, app: app)
    }
}
