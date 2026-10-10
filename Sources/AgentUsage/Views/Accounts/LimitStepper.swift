//
//  LimitStepper.swift
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

/// Stepper row for a usage limit stored in UserDefaults (tokens).
struct LimitStepper: View {
    @EnvironmentObject var store: UsageStore
    let title: String
    let key: String
    let defaultValue: Double
    let step: Double
    let minimum: Double
    var refreshOnChange = false
    var format: (Double) -> String = { Fmt.short($0) }
    @State private var value: Double = 0

    var body: some View {
        HStack {
            Text(title).font(LX.font(13)).foregroundColor(LX.text2)
            Spacer()
            HStack(spacing: 0) {
                button("minus") { set(value - step) }
                Text(format(value)).font(LX.font(12, .semibold)).foregroundColor(LX.text)
                    .monospacedDigit().frame(width: 48, height: 26)
                button("plus") { set(value + step) }
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(LX.surface))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(LX.border, lineWidth: 1))
        }
        .onAppear { value = UserDefaults.standard.object(forKey: key) as? Double ?? defaultValue }
    }

    private func button(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold)).foregroundColor(LX.text2)
                .frame(width: 28, height: 26).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func set(_ v: Double) {
        value = max(minimum, v)
        UserDefaults.standard.set(value, forKey: key)
        store.objectWillChange.send()
        if refreshOnChange { store.refresh() }
    }
}
