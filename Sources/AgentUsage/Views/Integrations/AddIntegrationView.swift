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
    @StateObject private var viewModel: AddIntegrationViewModel

    init(viewModel: @autoclosure @escaping () -> AddIntegrationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Text(viewModel.intro).font(LX.font(12)).foregroundColor(LX.text2)
                .fixedSize(horizontal: false, vertical: true)
            providers
            credentials
            field("Account name", icon: "person", accent: false) {
                TextField(viewModel.provider.displayName, text: $viewModel.name).textFieldStyle(.plain)
                    .font(LX.font(13)).foregroundColor(LX.text)
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").font(.system(size: 11)).foregroundColor(LX.text3)
                Text(viewModel.helpText).font(LX.font(11))
                    .foregroundColor(viewModel.isError ? LX.danger : LX.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            submitButton
            if viewModel.isEditing {
                Button("Cancel editing", action: viewModel.stopEditing)
                    .buttonStyle(.plain).font(LX.font(12)).foregroundColor(LX.text2)
                    .frame(maxWidth: .infinity)
            }
            connected
            Footer(viewModel: viewModel.footer)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: viewModel.back) {
                Image(systemName: "chevron.left").font(.system(size: 14, weight: .medium))
                    .foregroundColor(LX.text2)
            }.buttonStyle(.plain)
            Text(viewModel.title).font(LX.font(20, .semibold)).foregroundColor(LX.text)
        }
    }

    private var providers: some View {
        HStack(spacing: 8) {
            ForEach(ProviderKind.allCases) { kind in
                let on = viewModel.provider == kind
                Button {
                    viewModel.select(kind)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: kind.symbol).font(.system(size: 16))
                            .foregroundColor(on ? LX.accentText : LX.text3)
                        Text(kind.displayName).font(LX.font(11, .medium))
                            .foregroundColor(on ? LX.text : LX.text2)
                        Text(kind.isAvailable ? " " : "Soon").font(LX.font(9)).foregroundColor(LX.text3)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(on ? LX.accentSoft : LX.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(
                            on ? LX.accentLine : LX.border, lineWidth: 1)
                    )
                    .opacity(viewModel.isEnabled(kind) ? 1 : 0.4)
                }
                .buttonStyle(.plain).disabled(!viewModel.isEnabled(kind))
            }
        }
    }

    @ViewBuilder private var credentials: some View {
        if viewModel.awaitingCode {
            field("Paste code", icon: "number", accent: true) {
                TextField("code#state", text: $viewModel.code).textFieldStyle(.plain)
                    .font(LX.font(13)).foregroundColor(LX.text)
            }
        } else if viewModel.showsTokenField {
            field(viewModel.provider.tokenLabel, icon: "key", accent: true) {
                Group {
                    if viewModel.reveal {
                        TextField(viewModel.tokenPrompt, text: $viewModel.token)
                    } else {
                        SecureField(viewModel.tokenPrompt, text: $viewModel.token)
                    }
                }.textFieldStyle(.plain).font(LX.font(13)).foregroundColor(LX.text)
                Button {
                    viewModel.reveal.toggle()
                } label: {
                    Image(systemName: viewModel.reveal ? "eye.slash" : "eye").font(.system(size: 12))
                        .foregroundColor(LX.text3)
                }.buttonStyle(.plain)
            }
        }
    }

    private var submitButton: some View {
        Button(action: viewModel.submit) {
            HStack(spacing: 8) {
                if viewModel.busy { ProgressView().controlSize(.small) }
                Text(viewModel.buttonTitle)
            }
        }
        .buttonStyle(PrimaryButtonStyle(enabled: viewModel.canSubmit)).disabled(!viewModel.canSubmit)
    }

    private var connected: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label10(text: "Connected")
            ForEach(viewModel.accounts) { a in
                IntegrationRow(
                    account: a,
                    onEdit: a.integrationID == nil ? nil : { viewModel.startEditing(a) },
                    onRemove: { viewModel.remove(a) })
            }
            if viewModel.accounts.isEmpty {
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
}
