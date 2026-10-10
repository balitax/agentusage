//
//  MonthlyView.swift
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

struct MonthlyView: View {
    @EnvironmentObject var store: UsageStore
    @State private var hovered: Int?

    private var viewIndex: Binding<Int> {
        Binding(get: { 1 }, set: { if $0 == 0 { store.screen = .overview } })
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        let t = store.total
        let months = t.monthlyTotals(6)
        let prev = months.count > 1 ? months[months.count - 2].1 : 0
        let dayNo = Double(Calendar.current.component(.day, from: Date()))
        let dim = Double(Calendar.current.range(of: .day, in: .month, for: Date())!.count)
        let pace = t.month / dayNo * dim
        let chartMax = max(months.map(\.1).max() ?? 1, 1)

        VStack(spacing: 16) {
            BrandHeader()
            TabsControl(items: ["Daily", "Monthly"], selection: viewIndex)
            VStack(alignment: .leading, spacing: 4) {
                Text(monthTitle).font(LX.font(12)).foregroundColor(LX.text3)
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(Fmt.tokens(t.month)).font(LX.font(44, .semibold)).foregroundColor(LX.text)
                        .monospacedDigit()
                    Text("tokens").font(LX.font(13)).foregroundColor(LX.text2)
                }
                Text(
                    prev > 0
                        ? "\(pace >= prev ? "↑" : "↓") \(abs(Int((pace / prev - 1) * 100)))% vs last month (projected)"
                        : "No earlier data"
                ).font(LX.font(12)).foregroundColor(LX.accentText)
            }.frame(maxWidth: .infinity, alignment: .leading)
            chart(months, chartMax)
            Hairline()
            byAccount(t)
            Footer()
        }
    }

    private func chart(_ monthly: [(String, Double)], _ cmax: Double) -> some View {
        VStack(spacing: 8) {
            GeometryReader { g in
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Array(monthly.enumerated()), id: \.offset) { i, m in
                            let last = i == monthly.count - 1
                            RoundedRectangle(cornerRadius: 4)
                                .fill(last ? LX.accent : LX.bar)
                                .opacity(hovered == nil || hovered == i ? 1 : 0.45)
                                .frame(height: max(2, 96 * m.1 / cmax))
                        }
                    }.frame(height: 96, alignment: .bottom)
                    if let i = hovered, monthly.indices.contains(i) {
                        tooltip(monthly, i, width: g.size.width)
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let p):
                        hovered = min(
                            max(Int(p.x / g.size.width * CGFloat(monthly.count)), 0), monthly.count - 1)
                    case .ended: hovered = nil
                    }
                }
            }.frame(height: 96)
            HStack(spacing: 12) {
                ForEach(Array(monthly.enumerated()), id: \.offset) { i, m in
                    Text(m.0.capitalized).font(LX.font(10, i == monthly.count - 1 ? .semibold : .regular))
                        .foregroundColor(i == monthly.count - 1 ? LX.text : LX.text3)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .zIndex(2)
    }

    private func tooltip(_ monthly: [(String, Double)], _ i: Int, width: CGFloat) -> some View {
        let value = monthly[i].1
        var lines = ["\(Int((value / Caps.month * 100).rounded()))% of ~\(Fmt.short(Caps.month)) cap"]
        if i > 0, monthly[i - 1].1 > 0 {
            let d = Int(((value / monthly[i - 1].1) - 1) * 100)
            lines.append("\(d >= 0 ? "↑" : "↓") \(abs(d))% vs \(monthly[i - 1].0.capitalized)")
        }
        let x = (CGFloat(i) + 0.5) / CGFloat(monthly.count) * width
        let title = i == monthly.count - 1 ? "\(monthly[i].0.capitalized) (so far)" : monthly[i].0.capitalized
        return ChartTooltip(title: title, value: Fmt.tokens(value) + " tokens", lines: lines)
            .offset(x: min(max(x - 60, 0), width - 150), y: -78)
    }

    private func byAccount(_ t: Account) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By account").font(LX.font(12)).foregroundColor(LX.text3)
            ForEach(store.accounts) { a in
                HStack(spacing: 8) {
                    Circle().fill(a.color).frame(width: 6, height: 6)
                    Text(a.name).font(LX.font(13)).foregroundColor(LX.text)
                    Spacer()
                    Text(Fmt.tokens(a.month)).font(LX.font(13, .semibold)).foregroundColor(LX.text)
                    Text("\(Int((a.month / max(t.month, 1) * 100).rounded()))%").font(LX.font(12))
                        .foregroundColor(LX.text3).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }
}
