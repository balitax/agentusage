//
//  UsageChartViewModel.swift
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

import Foundation

/// Hover state and tooltip content for the usage bar chart.
final class UsageChartViewModel: BaseViewModel {
    private let app: AppViewModel
    @Published var hovered: Int?

    init(app: AppViewModel) {
        self.app = app
        super.init()
        forward(app)
    }

    var buckets: [UsageBucket] { app.selected.timeBuckets(app.range) }
    var peak: Double { max(buckets.map(\.tokens).max() ?? 1, 1) }
    var rangeLabels: [String] { app.range.labels }

    func opacity(at index: Int, count: Int) -> Double {
        if let hovered { return index == hovered ? 1 : 0.3 }
        return index >= count - 4 ? 1 : 0.5
    }

    func hover(fraction: Double) {
        let count = buckets.count
        hovered = min(max(Int(fraction * Double(count)), 0), count - 1)
    }

    func endHover() { hovered = nil }

    /// Tooltip for the hovered bar.
    var tooltip: ChartTooltipData? {
        let all = buckets
        guard let i = hovered, all.indices.contains(i) else { return nil }
        let b = all[i]
        let total = all.map(\.tokens).reduce(0, +)
        let average = total / Double(all.count)
        var lines: [String] = []
        if b.tokens == 0 {
            lines = ["No activity"]
        } else {
            if total > 0 { lines.append("\(Int((b.tokens / total * 100).rounded()))% of range total") }
            if average > 0 { lines.append(String(format: "%.1f× average", b.tokens / average)) }
        }
        return ChartTooltipData(title: label(for: b), value: Fmt.tokens(b.tokens) + " tokens", lines: lines)
    }

    private func label(for b: UsageBucket) -> String {
        let f = DateFormatter()
        switch app.range {
        case .h1, .h6, .d1:
            f.dateFormat = "HH:mm"
            return "\(f.string(from: b.start)) – \(f.string(from: b.end))"
        case .d7, .d30:
            f.dateFormat = "EEE d MMM, HH:mm"
            return f.string(from: b.start)
        }
    }
}
