//
//  OverviewViewModel.swift
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

/// Overview of the selected account: windows, token summary, chart or Copilot credits.
final class OverviewViewModel: BaseViewModel {
    private let app: AppViewModel
    let header: BrandHeaderViewModel
    let footer: FooterViewModel
    let chart: UsageChartViewModel

    init(
        app: AppViewModel, header: BrandHeaderViewModel, footer: FooterViewModel, chart: UsageChartViewModel
    ) {
        self.app = app
        self.header = header
        self.footer = footer
        self.chart = chart
        super.init()
        forward(app)
    }

    private var account: Account { app.selected }

    /// Present for plans measured in monthly AI credits (Copilot).
    var credits: CreditUsage? { account.credits }

    // MARK: Windows

    var fiveHour: Double { account.fiveHour }
    var sevenDay: Double { account.sevenDay }
    var fiveHourReset: String { "Resets in " + Fmt.duration(account.fiveReset) }
    var sevenDayReset: String { "Resets in " + Fmt.duration(account.sevenReset) }

    // MARK: Summary

    var todayText: String { Fmt.tokens(account.today) }
    var monthText: String { Fmt.tokens(account.month) }

    // MARK: Range tabs

    var rangeItems: [String] { UsageRange.allCases.map(\.rawValue) }
    var rangeIndex: Int {
        get { UsageRange.allCases.firstIndex(of: app.range) ?? 2 }
        set { app.range = UsageRange.allCases[newValue] }
    }

    // MARK: Credits

    var creditsReset: String {
        "Resets in " + Fmt.duration((credits?.resets ?? Date()).timeIntervalSinceNow)
    }

    var topModels: [(name: String, credits: Double)] {
        Array((credits?.models ?? []).prefix(5))
    }

    func formatCredits(_ value: Double) -> String { Int(value.rounded()).formatted() }
}
