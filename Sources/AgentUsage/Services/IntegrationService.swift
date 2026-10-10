//
//  IntegrationService.swift
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

/// Manages connected integrations: validation, persistence and Keychain storage.
final class IntegrationService: ObservableObject {
    @Published private(set) var integrations: [Integration] = Integration.loadAll()
    @Published private(set) var hiddenLocal: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: "hiddenLocal") ?? [])

    /// Called after any change so data can be reloaded.
    var onChange: () -> Void = {}

    func integration(id: String?) -> Integration? {
        integrations.first { $0.id == id }
    }

    // MARK: Connect

    /// Validates a token against the provider, then stores it in the Keychain.
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
        await append(item)
    }

    /// Exchanges the pasted OAuth code for credentials and stores them in the Keychain.
    func connectOAuth(name: String, input: String, pending: ClaudeOAuth.Pending) async throws {
        let creds = try await ClaudeOAuth.exchange(input: input, pending: pending)
        _ = try await ClaudeOAuth.usage(creds)
        let email = await ClaudeOAuth.email(creds)
        let item = Integration(
            provider: .claude, name: name.isEmpty ? (email ?? "Claude") : name, method: .oauth, email: email)
        KeychainStore.saveOAuth(creds, for: item.id)
        await append(item)
    }

    /// Renames an integration and optionally replaces its token (validated first).
    func update(_ id: String, name: String, token: String?) async throws {
        guard let current = integration(id: id) else { return }
        if let token, !token.isEmpty {
            if current.provider == .copilot {
                _ = try await CopilotProvider(token: token).creditUsage()
            } else {
                guard let p = current.provider.makeProvider(token: token) else {
                    throw UsageProviderError.invalidResponse
                }
                _ = try await p.events(since: Date().addingTimeInterval(-2 * 86400))
            }
            KeychainStore.save(token, for: id)
        }
        await MainActor.run {
            if !name.isEmpty, let i = integrations.firstIndex(where: { $0.id == id }) {
                integrations[i].name = name
            }
            Integration.saveAll(integrations)
            onChange()
        }
    }

    // MARK: Remove

    /// Removes any account: integrations are deleted, local sources are hidden.
    func remove(_ account: Account) {
        if let id = account.integrationID {
            disconnect(id)
        } else {
            hiddenLocal.insert(account.id)
            UserDefaults.standard.set(Array(hiddenLocal), forKey: "hiddenLocal")
            onChange()
        }
    }

    func restoreHidden() {
        hiddenLocal = []
        UserDefaults.standard.removeObject(forKey: "hiddenLocal")
        onChange()
    }

    func disconnect(_ id: String) {
        KeychainStore.delete(id)
        integrations.removeAll { $0.id == id }
        Integration.saveAll(integrations)
        onChange()
    }

    private func append(_ item: Integration) async {
        await MainActor.run {
            integrations.append(item)
            Integration.saveAll(integrations)
            onChange()
        }
    }
}
