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
    @StateObject private var viewModel: OverviewViewModel

    init(viewModel: @autoclosure @escaping () -> OverviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        if let credits = viewModel.credits {
            CreditsView(viewModel: viewModel, credits: credits)
        } else {
            usageBody
        }
    }

    private var usageBody: some View {
        VStack(spacing: 16) {
            BrandHeader(viewModel: viewModel.header)
            WindowRow(title: "5-hour window", value: viewModel.fiveHour, reset: viewModel.fiveHourReset)
            WindowRow(
                title: "7-day window", value: viewModel.sevenDay, reset: viewModel.sevenDayReset,
                highlight: false)
            Hairline()
            TabsControl(items: viewModel.rangeItems, selection: $viewModel.rangeIndex)
            UsageChart(viewModel: viewModel.chart)
            HStack {
                summary("Today", viewModel.todayText)
                Spacer()
                summary("This month", viewModel.monthText)
            }
            Footer(viewModel: viewModel.footer)
        }
    }

    private func summary(_ label: String, _ value: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(label).font(LX.font(12)).foregroundColor(LX.text3)
            Text(value).font(LX.font(12, .semibold)).foregroundColor(LX.text)
        }
    }
}
