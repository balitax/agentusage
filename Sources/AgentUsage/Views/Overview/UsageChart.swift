//
//  UsageChart.swift
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

struct UsageChart: View {
    @EnvironmentObject var store: UsageStore
    let account: Account
    @State private var hovered: Int?

    private let chartHeight: CGFloat = 72

    var body: some View {
        let buckets = account.timeBuckets(store.range)
        let peak = max(buckets.map(\.tokens).max() ?? 1, 1)
        VStack(spacing: 6) {
            GeometryReader { g in
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(buckets.enumerated()), id: \.offset) { i, b in
                            RoundedRectangle(cornerRadius: 2).fill(LX.accent)
                                .opacity(opacity(i, count: buckets.count))
                                .frame(height: max(2, chartHeight * b.tokens / peak))
                        }
                    }.frame(height: chartHeight, alignment: .bottom)
                    if let i = hovered, buckets.indices.contains(i) {
                        tooltip(buckets[i], buckets: buckets, index: i, width: g.size.width)
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let p):
                        let i = Int(p.x / g.size.width * CGFloat(buckets.count))
                        hovered = min(max(i, 0), buckets.count - 1)
                    case .ended: hovered = nil
                    }
                }
            }.frame(height: chartHeight)
            HStack {
                ForEach(Array(store.range.labels.enumerated()), id: \.offset) { i, t in
                    Text(t).font(LX.font(10)).foregroundColor(LX.text3)
                    if i < store.range.labels.count - 1 { Spacer() }
                }
            }
        }
        .zIndex(2)
    }

    private func opacity(_ i: Int, count: Int) -> Double {
        if let h = hovered { return i == h ? 1 : 0.3 }
        return i >= count - 4 ? 1 : 0.5
    }

    private func tooltip(_ b: UsageBucket, buckets: [UsageBucket], index: Int, width: CGFloat) -> some View {
        let total = buckets.map(\.tokens).reduce(0, +)
        let avg = total / Double(buckets.count)
        var lines: [String] = []
        if total > 0 { lines.append("\(Int((b.tokens / total * 100).rounded()))% of range total") }
        if avg > 0 && b.tokens > 0 { lines.append(String(format: "%.1f× average", b.tokens / avg)) }
        if b.tokens == 0 { lines = ["No activity"] }
        let x = CGFloat(index) / CGFloat(buckets.count) * width
        return ChartTooltip(title: label(b), value: Fmt.tokens(b.tokens) + " tokens", lines: lines)
            .offset(x: min(max(x - 50, 0), width - 130), y: -92)
    }

    private func label(_ b: UsageBucket) -> String {
        let f = DateFormatter()
        switch store.range {
        case .h1, .h6, .d1:
            f.dateFormat = "HH:mm"
            return "\(f.string(from: b.start)) – \(f.string(from: b.end))"
        case .d7, .d30:
            f.dateFormat = "EEE d MMM, HH:mm"
            return f.string(from: b.start)
        }
    }
}
