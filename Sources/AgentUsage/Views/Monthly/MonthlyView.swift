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
    @StateObject private var viewModel: MonthlyViewModel

    init(viewModel: @autoclosure @escaping () -> MonthlyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 16) {
            BrandHeader(viewModel: viewModel.header)
            TabsControl(items: ["Daily", "Monthly"], selection: $viewModel.viewIndex)
            headline
            chart
            Hairline()
            byAccount
            Footer(viewModel: viewModel.footer)
        }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.monthTitle).font(LX.font(12)).foregroundColor(LX.text3)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(viewModel.totalText).font(LX.font(44, .semibold)).foregroundColor(LX.text)
                    .monospacedDigit()
                Text("tokens").font(LX.font(13)).foregroundColor(LX.text2)
            }
            Text(viewModel.projectionText).font(LX.font(12)).foregroundColor(LX.accentText)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chart: some View {
        let months = viewModel.months
        let cmax = viewModel.chartMax
        return VStack(spacing: 8) {
            GeometryReader { g in
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Array(months.enumerated()), id: \.offset) { i, m in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == months.count - 1 ? LX.accent : LX.bar)
                                .opacity(viewModel.hovered == nil || viewModel.hovered == i ? 1 : 0.45)
                                .frame(height: max(2, 96 * m.1 / cmax))
                        }
                    }.frame(height: 96, alignment: .bottom)
                    if let tip = viewModel.tooltip, let i = viewModel.hovered {
                        let x = (CGFloat(i) + 0.5) / CGFloat(months.count) * g.size.width
                        ChartTooltip(data: tip).offset(x: min(max(x - 60, 0), g.size.width - 150), y: -78)
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let p): viewModel.hover(fraction: p.x / g.size.width)
                    case .ended: viewModel.endHover()
                    }
                }
            }.frame(height: 96)
            HStack(spacing: 12) {
                ForEach(Array(months.enumerated()), id: \.offset) { i, m in
                    let last = i == months.count - 1
                    Text(m.0.capitalized).font(LX.font(10, last ? .semibold : .regular))
                        .foregroundColor(last ? LX.text : LX.text3).frame(maxWidth: .infinity)
                }
            }
        }
        .zIndex(2)
    }

    private var byAccount: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By account").font(LX.font(12)).foregroundColor(LX.text3)
            ForEach(viewModel.shares) { s in
                HStack(spacing: 8) {
                    Circle().fill(s.color).frame(width: 6, height: 6)
                    Text(s.name).font(LX.font(13)).foregroundColor(LX.text)
                    Spacer()
                    Text(s.tokens).font(LX.font(13, .semibold)).foregroundColor(LX.text)
                    Text(s.percent).font(LX.font(12)).foregroundColor(LX.text3)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }
}
