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
enum BucketClient {
    static func fetch(
        base: String, query: [URLQueryItem], headers: [String: String]
    ) async throws -> [[String: Any]] {
        var page: String?
        var all: [[String: Any]] = []
        for _ in 0..<60 {
            var comps = URLComponents(string: base)!
            comps.queryItems = query + (page.map { [URLQueryItem(name: "page", value: $0)] } ?? [])
            var req = URLRequest(url: comps.url!)
            req.timeoutInterval = 30
            headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw UsageProviderError.invalidResponse }
            if http.statusCode == 401 || http.statusCode == 403 {
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
            guard (json["has_more"] as? Bool) == true, let next = json["next_page"] as? String else { break }
            page = next
        }
        return all
    }

    static func int(_ any: Any?) -> Int { (any as? NSNumber)?.intValue ?? 0 }
}
