//
//  UsageRepository.swift
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

/// Source of truth for loaded accounts. Reloads on demand and once a minute.
final class UsageRepository: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var loading = true
    @Published private(set) var updated = Date()

    typealias Loader = (_ integrations: [Integration], _ hidden: Set<String>) async -> [Account]

    private let integrations: IntegrationService
    private let load: Loader
    private var timer: Timer?

    /// - Parameters:
    ///   - load: Builds the account list. Replace it in tests.
    ///   - autoRefresh: Loads immediately and then every minute.
    init(
        integrations: IntegrationService,
        load: @escaping Loader = { await AccountLoader.load(integrations: $0, hidden: $1) },
        autoRefresh: Bool = true
    ) {
        self.integrations = integrations
        self.load = load
        integrations.onChange = { [weak self] in self?.refresh() }
        guard autoRefresh else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit { timer?.invalidate() }

    /// Reloads in the background.
    func refresh() {
        Task.detached(priority: .utility) { [self] in await reload() }
    }

    /// Reloads and publishes the result.
    func reload() async {
        let loaded = await load(integrations.integrations, integrations.hiddenLocal)
        await MainActor.run {
            accounts = loaded
            updated = Date()
            loading = false
        }
    }
}
