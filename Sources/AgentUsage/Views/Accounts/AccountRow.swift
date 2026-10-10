//
//  AccountRow.swift
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

struct AccountRow: View {
    let a: Account
    let active: Bool
    var onEdit: (() -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        let warn = a.error != nil || a.nearLimit
        HStack(spacing: 12) {
            Avatar(letter: a.initial, active: active)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(a.name).font(LX.font(13, .semibold)).foregroundColor(LX.text)
                    if active { Circle().fill(LX.accent).frame(width: 6, height: 6) }
                    Spacer()
                    Text("\(Int(a.fiveHour * 100))%").font(LX.font(13, .semibold)).monospacedDigit()
                        .foregroundColor(warn ? LX.danger : LX.accentText)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(LX.track)
                        Capsule().fill(warn ? LX.danger : LX.accent)
                            .frame(width: max(6, g.size.width * min(1, a.fiveHour)))
                    }
                }.frame(height: 6)
                Text(caption).font(LX.font(11)).foregroundColor(warn ? LX.danger : LX.text3)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 10) {
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(LX.text3)
                    }.buttonStyle(.plain).help("Edit integration")
                }
                if let onRemove { RemoveButton(onConfirm: onRemove) }
            }
        }
        .padding(.vertical, 14).contentShape(Rectangle())
    }

    private var caption: String {
        if let e = a.error { return e }
        if a.nearLimit { return "Near limit · resets in \(Fmt.duration(a.fiveReset))" }
        if let c = a.credits {
            return
                "\(Int(c.used.rounded()).formatted()) of \(Int(c.allowance).formatted()) credits · \(a.email)"
        }
        return "\(a.email) · 7-day \(Int(a.sevenDay * 100))%"
    }
}
