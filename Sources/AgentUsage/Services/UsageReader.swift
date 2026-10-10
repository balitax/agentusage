//
//  UsageReader.swift
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

enum UsageReader {
    static let home = FileManager.default.homeDirectoryForCurrentUser

    struct Source {
        let dir: URL
        let configJSON: URL
    }

    static func discoverSources() -> [Source] {
        let fm = FileManager.default
        var result: [Source] = []
        let names = (try? fm.contentsOfDirectory(atPath: home.path)) ?? []
        for n in names.sorted() where n == ".claude" || n.hasPrefix(".claude-") || n.hasPrefix(".claude_") {
            let dir = home.appendingPathComponent(n)
            guard fm.fileExists(atPath: dir.appendingPathComponent("projects").path) else { continue }
            let inside = dir.appendingPathComponent(".claude.json")
            let cfg =
                fm.fileExists(atPath: inside.path)
                ? inside : (n == ".claude" ? home.appendingPathComponent(".claude.json") : inside)
            result.append(Source(dir: dir, configJSON: cfg))
        }
        for extra in UserDefaults.standard.stringArray(forKey: "extraConfigDirs") ?? [] {
            let dir = URL(fileURLWithPath: (extra as NSString).expandingTildeInPath)
            if !result.contains(where: { $0.dir == dir }) {
                result.append(Source(dir: dir, configJSON: dir.appendingPathComponent(".claude.json")))
            }
        }
        return result
    }

    static func identity(_ cfg: URL) -> (name: String?, email: String?, plan: String) {
        guard let data = try? Data(contentsOf: cfg),
            let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let o = j["oauthAccount"] as? [String: Any]
        else { return (nil, nil, "—") }
        let tier = ((o["seatTier"] as? String) ?? (o["organizationType"] as? String) ?? "").lowercased()
        let plan =
            tier.contains("max")
            ? "MAX"
            : tier.contains("pro")
                ? "PRO" : tier.contains("team") ? "TEAM" : tier.contains("enterprise") ? "ENT" : "—"
        return (o["displayName"] as? String, o["emailAddress"] as? String, plan)
    }

    static func loadEvents(dir: URL, since: Date) -> [UsageEvent] {
        let fm = FileManager.default
        let root = dir.appendingPathComponent("projects")
        guard
            let en = fm.enumerator(
                at: root, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey])
        else { return [] }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        var byID: [String: UsageEvent] = [:]
        var anon: [UsageEvent] = []
        for case let url as URL in en where url.pathExtension == "jsonl" {
            if let m = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate, m < since
            {
                continue
            }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for line in text.split(separator: "\n") where line.contains("\"usage\"") {
                guard let d = line.data(using: .utf8),
                    let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                    let msg = j["message"] as? [String: Any],
                    let u = msg["usage"] as? [String: Any],
                    let ts = j["timestamp"] as? String,
                    let t = iso.date(from: ts) ?? iso2.date(from: ts), t >= since
                else { continue }
                func n(_ k: String) -> Int { (u[k] as? NSNumber)?.intValue ?? 0 }
                let total = n("input_tokens") + n("output_tokens") + n("cache_creation_input_tokens")
                guard total > 0 else { continue }
                let ev = UsageEvent(time: t, tokens: total)
                if let id = msg["id"] as? String { byID[id] = ev } else { anon.append(ev) }
            }
        }
        return (Array(byID.values) + anon).sorted { $0.time < $1.time }
    }
}
