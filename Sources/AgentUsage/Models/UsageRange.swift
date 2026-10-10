//
//  UsageRange.swift
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

/// Time range options for the usage chart.
enum UsageRange: String, CaseIterable {
    case h1 = "1h"
    case h6 = "6h"
    case d1 = "1d"
    case d7 = "7d"
    case d30 = "30d"

    var seconds: TimeInterval {
        switch self {
        case .h1: return 3600
        case .h6: return 6 * 3600
        case .d1: return 86400
        case .d7: return 7 * 86400
        case .d30: return 30 * 86400
        }
    }

    var labels: [String] {
        switch self {
        case .h1: return ["-1h", "-40m", "-20m", "Now"]
        case .h6: return ["-6h", "-4h", "-2h", "Now"]
        case .d1: return ["-24h", "-16h", "-8h", "Now"]
        case .d7: return ["-7d", "-5d", "-3d", "Now"]
        case .d30: return ["-30d", "-20d", "-10d", "Now"]
        }
    }
}
