//
//  UsageStore.swift
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

final class UsageStore: ObservableObject {
    @Published var screen: Screen =
        UserDefaults.standard.bool(forKey: "onboarded") ? .overview : .onboarding
    @Published var onboardingStep = 0
    @Published var accounts: [Account] = []
    @Published var selectedID: String?
    @Published var range: UsageRange = .d1
    @Published var updated = Date()
    @Published var loading = true
    @Published var showHighest: Bool {
        didSet { UserDefaults.standard.set(showHighest, forKey: "showHighest") }
    }
    private var timer: Timer?

    init() {
        showHighest = UserDefaults.standard.object(forKey: "showHighest") as? Bool ?? false
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
    }

    var selected: Account {
        accounts.first { $0.id == selectedID } ?? accounts.first
            ?? Account(
                id: "none", name: "No account", email: "Nothing connected", plan: "—", color: LX.accent)
    }
    var total: Account {
        Account(
            id: "all", name: "All Accounts", email: "", plan: "", color: LX.accent,
            events: accounts.flatMap(\.events).sorted { $0.time < $1.time })
    }

    /// Account whose limits the menu bar icon reflects.
    private var menuBarAccount: Account? {
        if screen == .monthly { return total }
        return showHighest ? accounts.max { $0.fiveHour < $1.fiveHour } : selected
    }
    var menuBarFive: Double { menuBarAccount?.fiveHour ?? 0 }
    var menuBarSeven: Double { menuBarAccount?.sevenDay ?? 0 }
    var menuBarPending: Bool { loading || screen == .onboarding || accounts.isEmpty }

    var isOnboarding: Bool { !UserDefaults.standard.bool(forKey: "onboarded") }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarded")
        onboardingStep = 0
        screen = .overview
    }

    // MARK: - Integrations

    @Published var integrations: [Integration] = Integration.loadAll()
    @Published var editingID: String?
    @Published var hiddenLocal: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: "hiddenLocal") ?? [])

    /// Validates the token against the provider, then stores it in the Keychain.
    func connect(provider kind: ProviderKind, name: String, token: String) async throws {
        var username: String?
        if kind == .copilot {
            username = try await CopilotProvider(token: token).creditUsage().username
        } else {
            guard let provider = kind.makeProvider(token: token) else {
                throw UsageProviderError.invalidResponse
            }
            _ = try await provider.events(since: Date().addingTimeInterval(-2 * 86400))
        }
        let item = Integration(
            provider: kind, name: name.isEmpty ? (username ?? kind.displayName) : name, email: username)
        KeychainStore.save(token, for: item.id)
        await MainActor.run {
            integrations.append(item)
            Integration.saveAll(integrations)
            refresh()
        }
    }

    /// Exchanges the pasted OAuth code for credentials and stores them in the Keychain.
    func connectOAuth(name: String, input: String, pending: ClaudeOAuth.Pending) async throws {
        let creds = try await ClaudeOAuth.exchange(input: input, pending: pending)
        _ = try await ClaudeOAuth.usage(creds)
        let email = await ClaudeOAuth.email(creds)
        let item = Integration(
            provider: .claude, name: name.isEmpty ? (email ?? "Claude") : name, method: .oauth, email: email)
        KeychainStore.saveOAuth(creds, for: item.id)
        await MainActor.run {
            integrations.append(item)
            Integration.saveAll(integrations)
            refresh()
        }
    }

    /// Renames an integration and optionally replaces its token (validated first).
    func update(_ id: String, name: String, token: String?) async throws {
        guard let i = integrations.firstIndex(where: { $0.id == id }) else { return }
        if let token, !token.isEmpty {
            if integrations[i].provider == .copilot {
                _ = try await CopilotProvider(token: token).creditUsage()
            } else {
                guard let p = integrations[i].provider.makeProvider(token: token) else {
                    throw UsageProviderError.invalidResponse
                }
                _ = try await p.events(since: Date().addingTimeInterval(-2 * 86400))
            }
            KeychainStore.save(token, for: id)
        }
        await MainActor.run {
            if !name.isEmpty { integrations[i].name = name }
            Integration.saveAll(integrations)
            editingID = nil
            refresh()
        }
    }

    /// Removes any account: integrations are deleted, local sources are hidden.
    func remove(_ account: Account) {
        if let id = account.integrationID {
            disconnect(id)
        } else {
            hiddenLocal.insert(account.id)
            UserDefaults.standard.set(Array(hiddenLocal), forKey: "hiddenLocal")
            refresh()
        }
    }

    func restoreHidden() {
        hiddenLocal = []
        UserDefaults.standard.removeObject(forKey: "hiddenLocal")
        refresh()
    }

    func disconnect(_ id: String) {
        KeychainStore.delete(id)
        integrations.removeAll { $0.id == id }
        Integration.saveAll(integrations)
        refresh()
    }

    // MARK: - Loading

    func refresh() {
        let colors = [LX.accent, LX.text2, LX.text3, LX.danger]
        let since = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let integrations = self.integrations
        let hidden = self.hiddenLocal
        Task.detached(priority: .utility) {
            let sources = UsageReader.discoverSources().filter { !hidden.contains($0.dir.path) }
            var result: [Account] = []
            for (i, s) in sources.enumerated() {
                let id = UsageReader.identity(s.configJSON)
                let fallback =
                    s.dir.lastPathComponent == ".claude"
                    ? "Personal"
                    : s.dir.lastPathComponent.replacingOccurrences(of: ".claude-", with: "").capitalized
                var a = Account(
                    id: s.dir.path, name: id.name ?? fallback, email: id.email ?? s.dir.path, plan: id.plan,
                    color: colors[i % colors.count])
                a.events = UsageReader.loadEvents(dir: s.dir, since: since)
                result.append(a)
            }
            for item in integrations {
                if item.method == .oauth {
                    var remote: RemoteUsage?
                    var err: String?
                    do {
                        guard var creds = KeychainStore.readOAuth(item.id) else {
                            throw UsageProviderError.message(
                                "Claude login missing from Keychain. Sign in again.")
                        }
                        let fresh = try await ClaudeOAuth.valid(creds)
                        if fresh != creds {
                            KeychainStore.saveOAuth(fresh, for: item.id)
                            creds = fresh
                        }
                        remote = try await ClaudeOAuth.usage(creds)
                    } catch { err = error.localizedDescription }
                    if let i = result.firstIndex(where: {
                        $0.integrationID == nil && !item.isBlankEmail
                            && $0.email.caseInsensitiveCompare(item.email ?? "") == .orderedSame
                    }) {
                        result[i].remote = remote
                        result[i].integrationID = item.id
                        result[i].source = "Claude login"
                        result[i].error = err
                    } else {
                        var a = Account(
                            id: item.id, name: item.name, email: item.email ?? "Claude · Login",
                            plan: "LOGIN", color: colors[result.count % colors.count])
                        a.remote = remote
                        a.source = "Claude login"
                        a.integrationID = item.id
                        a.error = err
                        result.append(a)
                    }
                    continue
                }
                if item.provider == .copilot {
                    var a = Account(
                        id: item.id, name: item.name, email: item.email.map { "@\($0)" } ?? "GitHub Copilot",
                        plan: "COPILOT", color: colors[result.count % colors.count])
                    a.provider = .copilot
                    a.source = "GitHub token"
                    a.integrationID = item.id
                    if let token = KeychainStore.read(item.id) {
                        do {
                            let r = try await CopilotProvider(token: token).creditUsage()
                            let allowance = Caps.copilotCredits
                            let reset = CreditUsage.nextReset
                            let pct = allowance > 0 ? r.used / allowance * 100 : 0
                            a.credits = CreditUsage(
                                used: r.used, allowance: allowance, resets: reset, models: r.models)
                            a.remote = RemoteUsage(
                                fiveHour: pct, fiveHourReset: reset, sevenDay: pct, sevenDayReset: reset)
                        } catch { a.error = error.localizedDescription }
                    } else {
                        a.error = "This integration needs to be reconnected. Remove it and add it again."
                    }
                    result.append(a)
                    continue
                }
                var a = Account(
                    id: item.id, name: item.name, email: "\(item.provider.displayName) · Admin API",
                    plan: "API", color: colors[result.count % colors.count])
                a.provider = item.provider
                a.source = "Admin API"
                a.integrationID = item.id
                if let token = KeychainStore.read(item.id), let p = item.provider.makeProvider(token: token) {
                    do { a.events = try await p.events(since: since) } catch {
                        a.error = error.localizedDescription
                    }
                } else {
                    a.error = "This integration needs to be reconnected. Remove it and add it again."
                }
                result.append(a)
            }
            let loaded = result
            await MainActor.run {
                self.accounts = loaded
                if self.selectedID == nil || !loaded.contains(where: { $0.id == self.selectedID }) {
                    self.selectedID = loaded.first?.id
                }
                self.updated = Date()
                self.loading = false
            }
        }
    }
}
