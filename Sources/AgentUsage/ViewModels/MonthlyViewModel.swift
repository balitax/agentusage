//
//  MonthlyViewModel.swift
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

/// Month total, 6-month chart (with hover) and the per-account breakdown.
final class MonthlyViewModel: BaseViewModel {
    struct AccountShare: Identifiable {
        let id: String
        let name: String
        let color: Color
        let tokens: String
        let percent: String
    }

    private let app: AppViewModel
    let header: BrandHeaderViewModel
    let footer: FooterViewModel
    @Published var hovered: Int?

    init(app: AppViewModel, header: BrandHeaderViewModel, footer: FooterViewModel) {
        self.app = app
        self.header = header
        self.footer = footer
        super.init()
        forward(app)
    }

    private var total: Account { app.total }
    var months: [(String, Double)] { total.monthlyTotals(6) }
    var chartMax: Double { max(months.map(\.1).max() ?? 1, 1) }

    // MARK: Headline

    var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    var totalText: String { Fmt.tokens(total.month) }

    /// Projected month-end compared with last month.
    var projectionText: String {
        let all = months
        let previous = all.count > 1 ? all[all.count - 2].1 : 0
        guard previous > 0 else { return "No earlier data" }
        let day = Double(Calendar.current.component(.day, from: Date()))
        let days = Double(Calendar.current.range(of: .day, in: .month, for: Date())!.count)
        let pace = total.month / day * days
        let change = Int((pace / previous - 1) * 100)
        return "\(pace >= previous ? "↑" : "↓") \(abs(change))% vs last month (projected)"
    }

    // MARK: Tabs

    var viewIndex: Int {
        get { 1 }
        set { if newValue == 0 { app.router.go(.overview) } }
    }

    // MARK: Hover

    func hover(fraction: Double) {
        let count = months.count
        hovered = min(max(Int(fraction * Double(count)), 0), count - 1)
    }

    func endHover() { hovered = nil }

    var tooltip: ChartTooltipData? {
        let all = months
        guard let i = hovered, all.indices.contains(i) else { return nil }
        let value = all[i].1
        var lines = ["\(Int((value / Caps.month * 100).rounded()))% of ~\(Fmt.short(Caps.month)) cap"]
        if i > 0, all[i - 1].1 > 0 {
            let d = Int(((value / all[i - 1].1) - 1) * 100)
            lines.append("\(d >= 0 ? "↑" : "↓") \(abs(d))% vs \(all[i - 1].0.capitalized)")
        }
        let name = all[i].0.capitalized
        return ChartTooltipData(
            title: i == all.count - 1 ? "\(name) (so far)" : name, value: Fmt.tokens(value) + " tokens",
            lines: lines)
    }

    // MARK: By account

    var shares: [AccountShare] {
        let sum = max(total.month, 1)
        return app.accounts.map {
            AccountShare(
                id: $0.id, name: $0.name, color: $0.color, tokens: Fmt.tokens($0.month),
                percent: "\(Int(($0.month / sum * 100).rounded()))%")
        }
    }
}
