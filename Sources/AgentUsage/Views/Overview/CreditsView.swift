//
//  CreditsView.swift
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

/// Overview for plans measured in monthly AI credits (GitHub Copilot).
struct CreditsView: View {
    @ObservedObject var viewModel: OverviewViewModel
    let credits: CreditUsage

    var body: some View {
        VStack(spacing: 16) {
            BrandHeader(viewModel: viewModel.header)
            WindowRow(title: "AI credits this month", value: credits.fraction, reset: viewModel.creditsReset)
            Hairline()
            VStack(alignment: .leading, spacing: 10) {
                Text("By model").font(LX.font(12)).foregroundColor(LX.text3)
                if credits.models.isEmpty {
                    Text("No usage yet this month.").font(LX.font(12)).foregroundColor(LX.text2)
                }
                ForEach(Array(viewModel.topModels.enumerated()), id: \.offset) { _, m in
                    HStack {
                        Text(m.name).font(LX.font(13)).foregroundColor(LX.text).lineLimit(1)
                        Spacer()
                        Text(viewModel.formatCredits(m.credits)).font(LX.font(13, .semibold))
                            .foregroundColor(LX.text).monospacedDigit()
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                summary("Used", viewModel.formatCredits(credits.used))
                Spacer()
                summary("Included", viewModel.formatCredits(credits.allowance))
                Spacer()
                summary("Left", viewModel.formatCredits(max(0, credits.allowance - credits.used)))
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
