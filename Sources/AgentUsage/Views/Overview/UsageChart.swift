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
    @ObservedObject var viewModel: UsageChartViewModel
    private let chartHeight: CGFloat = 72

    var body: some View {
        let buckets = viewModel.buckets
        let peak = viewModel.peak
        VStack(spacing: 6) {
            GeometryReader { g in
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(buckets.enumerated()), id: \.offset) { i, b in
                            RoundedRectangle(cornerRadius: 2).fill(LX.accent)
                                .opacity(viewModel.opacity(at: i, count: buckets.count))
                                .frame(height: max(2, chartHeight * b.tokens / peak))
                        }
                    }.frame(height: chartHeight, alignment: .bottom)
                    if let tip = viewModel.tooltip, let i = viewModel.hovered {
                        let x = CGFloat(i) / CGFloat(buckets.count) * g.size.width
                        ChartTooltip(data: tip)
                            .offset(x: min(max(x - 50, 0), g.size.width - 130), y: -92)
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let p): viewModel.hover(fraction: p.x / g.size.width)
                    case .ended: viewModel.endHover()
                    }
                }
            }.frame(height: chartHeight)
            HStack {
                ForEach(Array(viewModel.rangeLabels.enumerated()), id: \.offset) { i, t in
                    Text(t).font(LX.font(10)).foregroundColor(LX.text3)
                    if i < viewModel.rangeLabels.count - 1 { Spacer() }
                }
            }
        }
        .zIndex(2)
    }
}
