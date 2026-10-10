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
    @StateObject private var viewModel: AccountsViewModel

    init(viewModel: @autoclosure @escaping () -> AccountsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            list
            if viewModel.accounts.isEmpty {
                Text("No usage found. Tap Add to connect an account.")
                    .font(LX.font(12)).foregroundColor(LX.text2)
            }
            if viewModel.hiddenCount > 0 {
                Button(viewModel.restoreTitle, action: viewModel.restoreHidden)
                    .buttonStyle(.plain).font(LX.font(11)).foregroundColor(LX.accentText)
            }
            Hairline()
            menuBarToggle
            limits
            Footer(viewModel: viewModel.footer)
        }
    }

    private var header: some View {
        HStack {
            Text("Accounts").font(LX.font(20, .semibold)).foregroundColor(LX.text)
            Spacer()
            Button(action: viewModel.add) {
                Text("+ Add").font(LX.font(12, .semibold)).foregroundColor(LX.accentText)
            }.buttonStyle(.plain)
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { i, a in
                if i > 0 { Hairline() }
                Button {
                    viewModel.select(a)
                } label: {
                    AccountRow(
                        a: a, active: viewModel.isActive(a),
                        onEdit: a.integrationID == nil ? nil : { viewModel.edit(a) },
                        onRemove: { viewModel.remove(a) })
                }.buttonStyle(.plain)
            }
        }
    }

    private var menuBarToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Menu bar shows").font(LX.font(13, .medium)).foregroundColor(LX.text)
                Text(viewModel.menuBarSubtitle).font(LX.font(11)).foregroundColor(LX.text3)
            }
            Spacer()
            Toggle("", isOn: $viewModel.showHighest).labelsHidden().toggleStyle(.switch).tint(LX.accent)
        }
    }

    private var limits: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Usage limits").font(LX.font(13, .medium)).foregroundColor(LX.text)
                Text("Used to calculate % from local logs").font(LX.font(11)).foregroundColor(LX.text3)
            }
            LimitStepper(viewModel: viewModel.fiveHourLimit)
            LimitStepper(viewModel: viewModel.weeklyLimit)
            if viewModel.hasCopilot { LimitStepper(viewModel: viewModel.copilotLimit) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
