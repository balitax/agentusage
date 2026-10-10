//
//  AddIntegrationView.swift
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

struct AddIntegrationView: View {
    @EnvironmentObject var store: UsageStore
    @State private var provider: ProviderKind = .claude
    @State private var token = ""
    @State private var name = ""
    @State private var reveal = false
    @State private var busy = false
    @State private var message: String?
    @State private var pending: ClaudeOAuth.Pending?
    @State private var code = ""

    private var editing: Integration? { store.integrations.first { $0.id == store.editingID } }

    private var usesOAuth: Bool { provider == .claude }

    private var canConnect: Bool {
        if busy { return false }
        if editing != nil { return true }
        if usesOAuth { return pending == nil || !code.trimmingCharacters(in: .whitespaces).isEmpty }
        return provider.isAvailable && !token.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var helpMessage: String {
        usesOAuth
            ? "Opens claude.ai in your browser. Authorize, then paste the code it shows. Reads your real 5-hour and 7-day usage."
            : provider.helpText
    }

    private var buttonTitle: String {
        if busy { return "Checking…" }
        if editing != nil { return "Save changes" }
        if usesOAuth { return pending == nil ? "Sign in with Claude" : "Verify & connect" }
        return "Connect"
    }

    private var tokenPrompt: String {
        editing == nil ? provider.tokenPlaceholder : "Leave blank to keep current token"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Text(
                editing == nil
                    ? "Connect an account so Agent Usage can read your usage. Credentials stay in your Keychain."
                    : "Rename this integration or replace its token. A new token is verified before saving."
            )
            .font(LX.font(12)).foregroundColor(LX.text2).fixedSize(horizontal: false, vertical: true)
            providers
            if usesOAuth {
                if pending != nil && editing == nil {
                    field("Paste code", icon: "number", accent: true) {
                        TextField("code#state", text: $code).textFieldStyle(.plain)
                            .font(LX.font(13)).foregroundColor(LX.text)
                    }
                }
            } else {
                field(provider.tokenLabel, icon: "key", accent: true) {
                    Group {
                        if reveal {
                            TextField(tokenPrompt, text: $token)
                        } else {
                            SecureField(tokenPrompt, text: $token)
                        }
                    }.textFieldStyle(.plain).font(LX.font(13)).foregroundColor(LX.text)
                    Button {
                        reveal.toggle()
                    } label: {
                        Image(systemName: reveal ? "eye.slash" : "eye").font(.system(size: 12))
                            .foregroundColor(LX.text3)
                    }.buttonStyle(.plain)
                }
            }
            field("Account name", icon: "person", accent: false) {
                TextField(provider.displayName, text: $name).textFieldStyle(.plain)
                    .font(LX.font(13)).foregroundColor(LX.text)
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").font(.system(size: 11)).foregroundColor(LX.text3)
                Text(message ?? helpMessage).font(LX.font(11))
                    .foregroundColor(message == nil ? LX.text3 : LX.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: connect) {
                HStack(spacing: 8) {
                    if busy { ProgressView().controlSize(.small) }
                    Text(buttonTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle(enabled: canConnect)).disabled(!canConnect)
            if editing != nil {
                Button("Cancel editing") { stopEditing() }
                    .buttonStyle(.plain).font(LX.font(12)).foregroundColor(LX.text2)
                    .frame(maxWidth: .infinity)
            }
            connected
            Footer()
        }
        .onAppear { if let e = editing { load(e) } }
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                stopEditing()
                leave(connected: false)
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 14, weight: .medium))
                    .foregroundColor(LX.text2)
            }.buttonStyle(.plain)
            Text(editing == nil ? "Add integration" : "Edit integration")
                .font(LX.font(20, .semibold)).foregroundColor(LX.text)
        }
    }

    private var providers: some View {
        HStack(spacing: 8) {
            ForEach(ProviderKind.allCases) { k in
                let on = provider == k
                Button {
                    if editing == nil { provider = k }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: k.symbol).font(.system(size: 16))
                            .foregroundColor(on ? LX.accentText : LX.text3)
                        Text(k.displayName).font(LX.font(11, .medium))
                            .foregroundColor(on ? LX.text : LX.text2)
                        Text(k.isAvailable ? " " : "Soon").font(LX.font(9)).foregroundColor(LX.text3)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(on ? LX.accentSoft : LX.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(
                            on ? LX.accentLine : LX.border, lineWidth: 1)
                    )
                    .opacity(k.isAvailable && !(editing != nil && !on) ? 1 : 0.4)
                }
                .buttonStyle(.plain).disabled(!k.isAvailable)
            }
        }
    }

    private var connected: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label10(text: "Connected")
            ForEach(store.accounts) { a in
                IntegrationRow(
                    account: a,
                    onEdit: a.integrationID.map { id in { startEditing(id) } },
                    onRemove: { store.remove(a) })
            }
            if store.accounts.isEmpty {
                Text("Nothing connected yet.").font(LX.font(11)).foregroundColor(LX.text3)
            }
        }
    }

    private func field<C: View>(
        _ title: String, icon: String, accent: Bool, @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label10(text: title)
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(LX.text3)
                content()
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(LX.surface))
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(accent ? LX.accentLine : LX.border, lineWidth: 1))
        }
    }

    // MARK: Actions

    private func load(_ e: Integration) {
        provider = e.provider
        name = e.name
        token = ""
        message = nil
    }

    private func startEditing(_ id: String) {
        store.editingID = id
        if let e = editing { load(e) }
    }

    private func stopEditing() {
        store.editingID = nil
        token = ""
        name = ""
        message = nil
    }

    private func leave(connected: Bool) {
        if store.isOnboarding {
            store.onboardingStep = connected ? 2 : 1
            store.screen = .onboarding
        } else {
            store.screen = .accounts
        }
    }

    private func connect() {
        message = nil
        if usesOAuth && editing == nil && pending == nil {
            let p = ClaudeOAuth.begin()
            pending = p
            NSWorkspace.shared.open(p.url)
            return
        }
        busy = true
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                if usesOAuth && editing == nil, let p = pending {
                    try await store.connectOAuth(name: name, input: code, pending: p)
                } else if let e = editing {
                    try await store.update(e.id, name: name, token: t)
                } else {
                    try await store.connect(provider: provider, name: name, token: t)
                }
                await MainActor.run {
                    token = ""
                    name = ""
                    code = ""
                    pending = nil
                    busy = false
                    leave(connected: true)
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    busy = false
                }
            }
        }
    }
}
