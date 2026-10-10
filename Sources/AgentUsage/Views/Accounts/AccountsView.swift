//
//  AccountsView.swift
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

struct AccountsView: View {
    @EnvironmentObject var store: UsageStore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Accounts").font(LX.font(20, .semibold)).foregroundColor(LX.text)
                Spacer()
                Button {
                    store.editingID = nil
                    store.screen = .addIntegration
                } label: {
                    Text("+ Add").font(LX.font(12, .semibold)).foregroundColor(LX.accentText)
                }.buttonStyle(.plain)
            }
            VStack(spacing: 0) {
                ForEach(Array(store.accounts.enumerated()), id: \.element.id) { i, a in
                    if i > 0 { Hairline() }
                    Button {
                        store.selectedID = a.id
                        store.screen = .overview
                    } label: {
                        AccountRow(
                            a: a, active: a.id == store.selected.id,
                            onEdit: a.integrationID.map { id in { edit(id) } },
                            onRemove: { store.remove(a) })
                    }.buttonStyle(.plain)
                }
            }
            if store.accounts.isEmpty {
                Text("No usage found. Tap Add to connect an account.")
                    .font(LX.font(12)).foregroundColor(LX.text2)
            }
            if !store.hiddenLocal.isEmpty {
                Button(
                    "Restore \(store.hiddenLocal.count) hidden source\(store.hiddenLocal.count == 1 ? "" : "s")"
                ) { store.restoreHidden() }
                .buttonStyle(.plain).font(LX.font(11)).foregroundColor(LX.accentText)
            }
            Hairline()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menu bar shows").font(LX.font(13, .medium)).foregroundColor(LX.text)
                    Text(
                        store.showHighest
                            ? "Highest usage across all accounts" : "Follows the selected account"
                    ).font(LX.font(11)).foregroundColor(LX.text3)
                }
                Spacer()
                Toggle("", isOn: $store.showHighest).labelsHidden().toggleStyle(.switch).tint(LX.accent)
            }
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Usage limits").font(LX.font(13, .medium)).foregroundColor(LX.text)
                    Text("Used to calculate % from local logs").font(LX.font(11)).foregroundColor(LX.text3)
                }
                LimitStepper(
                    title: "5-hour limit", key: "capFiveHour", defaultValue: 1_500_000, step: 500_000,
                    minimum: 500_000)
                LimitStepper(
                    title: "Weekly limit", key: "capSevenDay", defaultValue: 20_000_000, step: 5_000_000,
                    minimum: 5_000_000)
                if store.accounts.contains(where: { $0.provider == .copilot }) {
                    LimitStepper(
                        title: "Copilot credits / month", key: "capCopilotCredits", defaultValue: 1_500,
                        step: 500,
                        minimum: 500, refreshOnChange: true, format: { Int($0).formatted() })
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Footer()
        }
    }

    private func edit(_ id: String) {
        store.editingID = id
        store.screen = .addIntegration
    }
}
