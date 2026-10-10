//
//  Footer.swift
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

/// Status line with text actions.
struct Footer: View {
    @EnvironmentObject var store: UsageStore

    var body: some View {
        VStack(spacing: 12) {
            Hairline()
            HStack {
                Text(
                    store.loading
                        ? "Loading…" : "Updated \(store.updated.formatted(.relative(presentation: .numeric)))"
                )
                .font(LX.font(11)).foregroundColor(LX.text3)
                Spacer()
                HStack(spacing: 16) {
                    link("Accounts") { store.screen = store.screen == .accounts ? .overview : .accounts }
                    link("Refresh") { store.refresh() }
                    link("Quit") { NSApplication.shared.terminate(nil) }
                }
            }
        }
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(LX.font(11, .medium)).foregroundColor(LX.text2)
        }.buttonStyle(.plain)
    }
}
