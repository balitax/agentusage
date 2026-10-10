//
//  BucketClient.swift
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

/// Shared paginated fetcher for "usage bucket" style APIs (Anthropic, OpenAI).
///
/// Both vendors return usage as an array under `data`, with a `has_more`/`next_page`
/// cursor pointing at the following page. This helper walks that cursor and
/// concatenates every page into one flat array, translating HTTP failures into
/// `UsageProviderError`.
enum BucketClient {
    /// Fetches all pages for a usage query and returns their raw `data` buckets combined.
    ///
    /// - Parameters:
    ///   - base: The endpoint URL without the `page` cursor (e.g. the OpenAI usage URL).
    ///   - query: Query items common to every page (time range, bucket width, limit).
    ///   - headers: Request headers, typically the `Authorization` bearer token.
    /// - Returns: Every bucket from every page, in server order.
    /// - Throws: `UsageProviderError.unauthorized` on 401/403, `.http` on other non-200
    ///   responses, and `.invalidResponse` when the body is missing or malformed.
    static func fetch(
        base: String, query: [URLQueryItem], headers: [String: String]
    ) async throws -> [[String: Any]] {
        var page: String?
        var all: [[String: Any]] = []
        // Bounded loop: a safety cap so a server that never clears `has_more` can't spin forever.
        for _ in 0..<60 {
            var comps = URLComponents(string: base)!
            // Append the cursor only from the second page onward.
            comps.queryItems = query + (page.map { [URLQueryItem(name: "page", value: $0)] } ?? [])
            var req = URLRequest(url: comps.url!)
            req.timeoutInterval = 30
            headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw UsageProviderError.invalidResponse }
            if http.statusCode == 401 || http.statusCode == 403 {
                // Surface the server's own error message when present, for a clearer diagnostic.
                let msg =
                    ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])
                    .flatMap { ($0["error"] as? [String: Any])?["message"] as? String }
                throw UsageProviderError.unauthorized(msg)
            }
            guard http.statusCode == 200 else { throw UsageProviderError.http(http.statusCode) }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let buckets = json["data"] as? [[String: Any]]
            else { throw UsageProviderError.invalidResponse }
            all += buckets
            // Stop as soon as the server reports no further pages.
            guard (json["has_more"] as? Bool) == true, let next = json["next_page"] as? String else { break }
            page = next
        }
        return all
    }

    /// Reads an integer out of loosely-typed JSON, defaulting to 0 for missing/non-numeric values.
    static func int(_ any: Any?) -> Int { (any as? NSNumber)?.intValue ?? 0 }
}
