//
//  OverviewView.swift
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

struct OverviewView: View {
    @EnvironmentObject var store: UsageStore

    private var rangeIndex: Binding<Int> {
        Binding(
            get: { UsageRange.allCases.firstIndex(of: store.range) ?? 2 },
            set: { store.range = UsageRange.allCases[$0] })
    }

    var body: some View {
        let a = store.selected
        if let credits = a.credits {
            CreditsView(account: a, credits: credits)
        } else {
            usageBody(a)
        }
    }

    private func usageBody(_ a: Account) -> some View {
        VStack(spacing: 16) {
            BrandHeader()
            WindowRow(
                title: "5-hour window", value: a.fiveHour, reset: "Resets in " + Fmt.duration(a.fiveReset))
            WindowRow(
                title: "7-day window", value: a.sevenDay, reset: "Resets in " + Fmt.duration(a.sevenReset),
                highlight: false)
            Hairline()
            TabsControl(items: UsageRange.allCases.map(\.rawValue), selection: rangeIndex)
            UsageChart(account: a)
            HStack {
                summary("Today", Fmt.tokens(a.today))
                Spacer()
                summary("This month", Fmt.tokens(a.month))
            }
            Footer()
        }
    }

    private func summary(_ label: String, _ value: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(label).font(LX.font(12)).foregroundColor(LX.text3)
            Text(value).font(LX.font(12, .semibold)).foregroundColor(LX.text)
        }
    }
}
