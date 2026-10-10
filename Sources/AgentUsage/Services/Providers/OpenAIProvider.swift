//
//  OpenAIProvider.swift
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

/// Reads usage from the OpenAI organization usage API (`/v1/organization/usage/completions`).
///
/// The API caps hourly granularity to the last ~35 days, so history is fetched in two
/// passes: recent days as hourly buckets and anything older as daily buckets.
struct OpenAIProvider: UsageProvider {
    /// Organization admin key used as the `Authorization` bearer token.
    let token: String
    private let base = "https://api.openai.com/v1/organization/usage/completions"

    /// Returns one `UsageEvent` per non-empty bucket between `since` and now, oldest first.
    func events(since: Date) async throws -> [UsageEvent] {
        let now = Date()
        // Hourly data is only available for the last ~35 days; clamp the hourly window to that.
        let hourlyStart = max(since, now.addingTimeInterval(-35 * 86400))
        var result = try await load(from: hourlyStart, to: now, width: "1h", limit: 168)
        // Anything older than the hourly window is backfilled at daily resolution.
        if since < hourlyStart {
            result += try await load(from: since, to: hourlyStart, width: "1d", limit: 31)
        }
        return result.sorted { $0.time < $1.time }
    }

    /// Fetches one time range at a given bucket width and folds each bucket's token
    /// counts (input + output across every result) into a single `UsageEvent`.
    /// Buckets with zero tokens are dropped.
    private func load(from: Date, to: Date, width: String, limit: Int) async throws -> [UsageEvent] {
        let buckets = try await BucketClient.fetch(
            base: base,
            query: [
                .init(name: "start_time", value: String(Int(from.timeIntervalSince1970))),
                .init(name: "end_time", value: String(Int(to.timeIntervalSince1970))),
                .init(name: "bucket_width", value: width),
                .init(name: "limit", value: String(limit)),
            ],
            headers: ["Authorization": "Bearer \(token)"])
        return buckets.compactMap { b in
            let t = Date(timeIntervalSince1970: TimeInterval(BucketClient.int(b["start_time"])))
            let results = b["results"] as? [[String: Any]] ?? []
            let total = results.reduce(0) {
                $0 + BucketClient.int($1["input_tokens"]) + BucketClient.int($1["output_tokens"])
            }
            return total > 0 ? UsageEvent(time: t, tokens: total) : nil
        }
    }
}
