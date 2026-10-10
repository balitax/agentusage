//
//  WindowRow.swift
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

/// A usage window: title, percentage, thick progress bar and reset caption.
struct WindowRow: View {
    let title: String
    let value: Double
    let reset: String
    var highlight = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(LX.font(13, .medium)).foregroundColor(LX.text)
                Spacer()
                Text("\(Int(value * 100))%").font(LX.font(13, .semibold)).monospacedDigit()
                    .foregroundColor(highlight ? LX.accentText : LX.text)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(LX.track)
                    Capsule().fill(highlight ? LX.accent : LX.text2)
                        .frame(width: max(10, g.size.width * min(1, value)))
                }
            }.frame(height: 10)
            Text(reset).font(LX.font(12)).foregroundColor(LX.text3)
        }
    }
}
