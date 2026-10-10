//
//  Account.swift
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

struct Account: Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let plan: String
    let color: Color
    var events: [UsageEvent] = []
    var provider: ProviderKind = .claude
    var source: String = "Local logs"
    var integrationID: String?
    var error: String?
    var remote: RemoteUsage?
    var credits: CreditUsage?

    static func == (a: Account, b: Account) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    var initial: String { String(name.prefix(1)).uppercased() }
    func sum(_ from: Date, _ to: Date = Date()) -> Double {
        Double(events.lazy.filter { $0.time >= from && $0.time <= to }.reduce(0) { $0 + $1.tokens })
    }

    var activeWindowEnd: Date? {
        var start: Date?
        for e in events {
            if let s = start, e.time < s.addingTimeInterval(5 * 3600) { continue }
            start = e.time
        }
        guard let s = start else { return nil }
        let end = s.addingTimeInterval(5 * 3600)
        return end > Date() ? end : nil
    }
    var fiveHourTokens: Double {
        guard let end = activeWindowEnd else { return 0 }
        return sum(end.addingTimeInterval(-5 * 3600))
    }
    var fiveHour: Double { remote?.fiveHour.map { $0 / 100 } ?? fiveHourTokens / Caps.fiveHour }
    var sevenDay: Double {
        remote?.sevenDay.map { $0 / 100 }
            ?? sum(Date().addingTimeInterval(-7 * 86400)) / Caps.sevenDay
    }
    var nearLimit: Bool { fiveHour >= 0.8 }
    var fiveReset: TimeInterval? {
        remote?.fiveHourReset.map { $0.timeIntervalSinceNow }
            ?? activeWindowEnd.map { $0.timeIntervalSinceNow }
    }
    var sevenReset: TimeInterval? {
        if let r = remote?.sevenDayReset { return r.timeIntervalSinceNow }
        return events.first { $0.time >= Date().addingTimeInterval(-7 * 86400) }.map {
            $0.time.addingTimeInterval(7 * 86400).timeIntervalSinceNow
        }
    }

    var cal: Calendar { Calendar.current }
    var today: Double { sum(cal.startOfDay(for: Date())) }
    var yesterday: Double {
        let s = cal.startOfDay(for: Date())
        return sum(s.addingTimeInterval(-86400), s)
    }
    var monthStart: Date { cal.dateInterval(of: .month, for: Date())!.start }
    var month: Double { sum(monthStart) }
    var dailyTotalsThisMonth: [(Date, Double)] {
        var d: [Date: Double] = [:]
        for e in events where e.time >= monthStart {
            d[cal.startOfDay(for: e.time), default: 0] += Double(e.tokens)
        }
        return d.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    func monthlyTotals(_ n: Int) -> [(String, Double)] {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return (0..<n).reversed().map { i in
            let m = cal.date(byAdding: .month, value: -i, to: monthStart)!
            let iv = cal.dateInterval(of: .month, for: m)!
            return (f.string(from: m).uppercased(), sum(iv.start, iv.end))
        }
    }
    func series(_ r: UsageRange, buckets: Int = 32) -> [Double] {
        timeBuckets(r, count: buckets).map(\.tokens)
    }

    /// Token totals split into equal time slices ending now.
    func timeBuckets(_ r: UsageRange, count: Int = 32) -> [UsageBucket] {
        let step = r.seconds / Double(count)
        let start = Date().addingTimeInterval(-r.seconds)
        var out = (0..<count).map {
            UsageBucket(
                start: start.addingTimeInterval(step * Double($0)),
                end: start.addingTimeInterval(step * Double($0 + 1)), tokens: 0)
        }
        for e in events where e.time >= start {
            out[min(count - 1, Int(e.time.timeIntervalSince(start) / step))].tokens += Double(e.tokens)
        }
        return out
    }
}
