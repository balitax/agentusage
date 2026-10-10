//
//  AddIntegrationViewModel.swift
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

import AppKit
import Foundation

/// Form state and actions for adding or editing an integration.
final class AddIntegrationViewModel: BaseViewModel {
    private let app: AppViewModel
    let footer: FooterViewModel

    @Published var provider: ProviderKind = .claude
    @Published var token = ""
    @Published var name = ""
    @Published var code = ""
    @Published var reveal = false
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    @Published private(set) var pending: ClaudeOAuth.Pending?

    init(app: AppViewModel, footer: FooterViewModel) {
        self.app = app
        self.footer = footer
        super.init()
        forward(app)
        loadEditing()
    }

    // MARK: Derived

    var accounts: [Account] { app.accounts }
    var editing: Integration? { app.integrations.integration(id: app.router.editingID) }
    var isEditing: Bool { editing != nil }
    var usesOAuth: Bool { provider == .claude }
    var awaitingCode: Bool { usesOAuth && !isEditing && pending != nil }
    var showsTokenField: Bool { !usesOAuth }

    var title: String { isEditing ? "Edit integration" : "Add integration" }

    var intro: String {
        isEditing
            ? "Rename this integration or replace its token. A new token is verified before saving."
            : "Connect an account so Agent Usage can read your usage. Credentials stay in your Keychain."
    }

    var helpText: String {
        message
            ?? (usesOAuth
                ? "Opens claude.ai in your browser. Authorize, then paste the code it shows. Reads your real 5-hour and 7-day usage."
                : provider.helpText)
    }

    var isError: Bool { message != nil }

    var tokenPrompt: String {
        isEditing ? "Leave blank to keep current token" : provider.tokenPlaceholder
    }

    var buttonTitle: String {
        if busy { return "Checking…" }
        if isEditing { return "Save changes" }
        if usesOAuth { return pending == nil ? "Sign in with Claude" : "Verify & connect" }
        return "Connect"
    }

    var canSubmit: Bool {
        if busy { return false }
        if isEditing { return true }
        if usesOAuth { return pending == nil || !code.trimmingCharacters(in: .whitespaces).isEmpty }
        return provider.isAvailable && !token.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func isEnabled(_ kind: ProviderKind) -> Bool {
        kind.isAvailable && !(isEditing && kind != provider)
    }

    // MARK: Actions

    func select(_ kind: ProviderKind) {
        if !isEditing { provider = kind }
    }

    func onAppear() { loadEditing() }

    func startEditing(_ account: Account) {
        guard let id = account.integrationID else { return }
        app.router.editingID = id
        loadEditing()
    }

    func stopEditing() {
        app.router.editingID = nil
        reset()
    }

    func back() {
        stopEditing()
        leave(connected: false)
    }

    func remove(_ account: Account) { app.integrations.remove(account) }

    func submit() {
        message = nil
        if usesOAuth && !isEditing && pending == nil {
            let p = ClaudeOAuth.begin()
            pending = p
            NSWorkspace.shared.open(p.url)
            return
        }
        busy = true
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.perform(token: t)
                await MainActor.run {
                    self.reset()
                    self.leave(connected: true)
                }
            } catch {
                await MainActor.run {
                    self.message = error.localizedDescription
                    self.busy = false
                }
            }
        }
    }

    // MARK: Private

    private func perform(token t: String) async throws {
        let service = app.integrations
        if usesOAuth, !isEditing, let p = pending {
            try await service.connectOAuth(name: name, input: code, pending: p)
        } else if let e = editing {
            try await service.update(e.id, name: name, token: t)
        } else {
            try await service.connect(provider: provider, name: name, token: t)
        }
    }

    private func loadEditing() {
        guard let e = editing else { return }
        provider = e.provider
        name = e.name
        token = ""
        message = nil
    }

    private func reset() {
        token = ""
        name = ""
        code = ""
        pending = nil
        busy = false
        message = nil
    }

    /// After connecting during onboarding, return to the walkthrough instead of Accounts.
    private func leave(connected: Bool) {
        if app.isOnboarding {
            app.router.onboardingStep = connected ? 2 : 1
            app.router.go(.onboarding)
        } else {
            app.router.go(.accounts)
        }
    }
}
