//
//  IntegrationRow.swift
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

struct IntegrationRow: View {
    let account: Account
    var onEdit: (() -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(account.error == nil ? LX.accent : LX.danger).frame(width: 6, height: 6)
            Text("\(account.provider.displayName) · \(account.name)").font(LX.font(12)).foregroundColor(
                LX.text)
            Spacer()
            Text(account.source).font(LX.font(11)).foregroundColor(LX.text3)
            if let onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundColor(LX.text3)
                }.buttonStyle(.plain).help("Edit integration")
            }
            if let onRemove { RemoveButton(onConfirm: onRemove) }
        }
    }
}
