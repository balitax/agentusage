//
//  AccountLoader.swift
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

/// Builds the list of accounts from local Claude Code logs and connected integrations.
enum AccountLoader {
    private static let colors = [LX.accent, LX.text2, LX.text3, LX.danger]
    private static let reconnectMessage =
        "This integration needs to be reconnected. Remove it and add it again."

    static func load(integrations: [Integration], hidden: Set<String>) async -> [Account] {
        let since = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        var result = localAccounts(hidden: hidden, since: since)
        for item in integrations {
            if item.method == .oauth {
                merge(await claudeLogin(item), into: &result)
            } else if item.provider == .copilot {
                result.append(await copilot(item, index: result.count))
            } else {
                result.append(await adminKey(item, index: result.count, since: since))
            }
        }
        return result
    }

    // MARK: Local logs

    private static func localAccounts(hidden: Set<String>, since: Date) -> [Account] {
        let sources = UsageReader.discoverSources().filter { !hidden.contains($0.dir.path) }
        return sources.enumerated().map { i, s in
            let id = UsageReader.identity(s.configJSON)
            let folder = s.dir.lastPathComponent
            let fallback =
                folder == ".claude"
                ? "Personal" : folder.replacingOccurrences(of: ".claude-", with: "").capitalized
            var a = Account(
                id: s.dir.path, name: id.name ?? fallback, email: id.email ?? s.dir.path, plan: id.plan,
                color: colors[i % colors.count])
            a.events = UsageReader.loadEvents(dir: s.dir, since: since)
            return a
        }
    }

    // MARK: Claude login

    private struct ClaudeLoginResult {
        let item: Integration
        let remote: RemoteUsage?
        let error: String?
    }

    private static func claudeLogin(_ item: Integration) async -> ClaudeLoginResult {
        do {
            guard var creds = KeychainStore.readOAuth(item.id) else {
                throw UsageProviderError.message("Claude login missing from Keychain. Sign in again.")
            }
            let fresh = try await ClaudeOAuth.valid(creds)
            if fresh != creds {
                KeychainStore.saveOAuth(fresh, for: item.id)
                creds = fresh
            }
            return ClaudeLoginResult(item: item, remote: try await ClaudeOAuth.usage(creds), error: nil)
        } catch {
            return ClaudeLoginResult(item: item, remote: nil, error: error.localizedDescription)
        }
    }

    /// Attaches the login to the matching local account (same email) or adds a new account.
    private static func merge(_ login: ClaudeLoginResult, into accounts: inout [Account]) {
        let item = login.item
        if let i = accounts.firstIndex(where: {
            $0.integrationID == nil && !item.isBlankEmail
                && $0.email.caseInsensitiveCompare(item.email ?? "") == .orderedSame
        }) {
            accounts[i].remote = login.remote
            accounts[i].integrationID = item.id
            accounts[i].source = "Claude login"
            accounts[i].error = login.error
        } else {
            var a = Account(
                id: item.id, name: item.name, email: item.email ?? "Claude · Login", plan: "LOGIN",
                color: colors[accounts.count % colors.count])
            a.remote = login.remote
            a.source = "Claude login"
            a.integrationID = item.id
            a.error = login.error
            accounts.append(a)
        }
    }

    // MARK: Copilot

    private static func copilot(_ item: Integration, index: Int) async -> Account {
        var a = Account(
            id: item.id, name: item.name, email: item.email.map { "@\($0)" } ?? "GitHub Copilot",
            plan: "COPILOT", color: colors[index % colors.count])
        a.provider = .copilot
        a.source = "GitHub token"
        a.integrationID = item.id
        guard let token = KeychainStore.read(item.id) else {
            a.error = reconnectMessage
            return a
        }
        do {
            let r = try await CopilotProvider(token: token).creditUsage()
            let allowance = Caps.copilotCredits
            let reset = CreditUsage.nextReset
            let pct = allowance > 0 ? r.used / allowance * 100 : 0
            a.credits = CreditUsage(used: r.used, allowance: allowance, resets: reset, models: r.models)
            a.remote = RemoteUsage(fiveHour: pct, fiveHourReset: reset, sevenDay: pct, sevenDayReset: reset)
        } catch {
            a.error = error.localizedDescription
        }
        return a
    }

    // MARK: Admin key (Codex)

    private static func adminKey(_ item: Integration, index: Int, since: Date) async -> Account {
        var a = Account(
            id: item.id, name: item.name, email: "\(item.provider.displayName) · Admin API", plan: "API",
            color: colors[index % colors.count])
        a.provider = item.provider
        a.source = "Admin API"
        a.integrationID = item.id
        guard let token = KeychainStore.read(item.id), let p = item.provider.makeProvider(token: token) else {
            a.error = reconnectMessage
            return a
        }
        do {
            a.events = try await p.events(since: since)
        } catch {
            a.error = error.localizedDescription
        }
        return a
    }
}
