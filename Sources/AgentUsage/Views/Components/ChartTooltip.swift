//
//  ChartTooltip.swift
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

/// Small floating card shown while hovering a chart bar.
struct ChartTooltip: View {
    let title: String
    let value: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(LX.font(10)).foregroundColor(LX.text3)
            Text(value).font(LX.font(13, .semibold)).foregroundColor(LX.text).monospacedDigit()
            ForEach(lines, id: \.self) { Text($0).font(LX.font(10)).foregroundColor(LX.text2) }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .fixedSize()
        .background(
            RoundedRectangle(cornerRadius: 10).fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(LX.border, lineWidth: 1))
        .allowsHitTesting(false)
    }
}
