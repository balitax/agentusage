//
//  CopilotProvider.swift
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

/// Reads GitHub Copilot AI-credit usage from the GitHub billing REST API.
/// Needs a fine-grained personal access token with the user permission "Plan: read".
struct CopilotProvider {
    /// Fine-grained GitHub PAT sent as the `Authorization` bearer token.
    let token: String

    /// A month's Copilot AI-credit spend, broken down per model.
    struct Result {
        /// The GitHub login the token belongs to.
        let username: String
        /// Total AI credits consumed this month (sum of `models`).
        let used: Double
        /// Per-model credit spend, highest first.
        let models: [(name: String, credits: Double)]
    }

    /// Resolves the token's user, fetches their current-month AI-credit billing, and
    /// aggregates it per model.
    ///
    /// - Throws: `UsageProviderError.message` with user-facing guidance for 401 (bad token),
    ///   403 (missing "Plan: read" permission) and 404 (no personal Copilot billing);
    ///   `.http` for other failures and `.invalidResponse` for a malformed body.
    func creditUsage() async throws -> Result {
        let username = try await fetchUsername()
        // Billing is scoped to a calendar month; GitHub expects UTC year/month.
        let comps = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(identifier: "UTC")!, from: Date())
        let (data, http) = try await get(
            "https://api.github.com/users/\(username)/settings/billing/ai_credit/usage?year=\(comps.year!)&month=\(comps.month!)"
        )
        switch http.statusCode {
        case 200: break
        case 401:
            throw UsageProviderError.message("GitHub rejected this token. Create a new one and try again.")
        case 403:
            throw UsageProviderError.message(
                "Token lacks permission. Enable Account permissions → Plan: Read on a fine-grained token.")
        case 404:
            throw UsageProviderError.message(
                "No personal Copilot billing found. This works for Copilot plans billed to your own account.")
        default: throw UsageProviderError.http(http.statusCode)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let items = json["usageItems"] as? [[String: Any]]
        else { throw UsageProviderError.invalidResponse }

        var perModel: [String: Double] = [:]
        for item in items {
            let unit = (item["unitType"] as? String ?? "").lowercased()
            let qty = (item["grossQuantity"] as? NSNumber)?.doubleValue ?? 0
            let amount = (item["grossAmount"] as? NSNumber)?.doubleValue ?? 0
            // Lines are reported either directly in credits or in dollars; 1 AI credit = US$0.01,
            // so dollar amounts are scaled up by 100 to a common credit unit.
            let credits = unit.contains("credit") ? qty : amount * 100
            perModel[item["model"] as? String ?? "Other", default: 0] += credits
        }
        let models = perModel.sorted { $0.value > $1.value }.map { (name: $0.key, credits: $0.value) }
        return Result(username: username, used: models.reduce(0) { $0 + $1.credits }, models: models)
    }

    /// Looks up the login name the token authenticates as (needed to build the billing URL).
    private func fetchUsername() async throws -> String {
        let (data, http) = try await get("https://api.github.com/user")
        if http.statusCode == 401 {
            throw UsageProviderError.message("GitHub rejected this token. Create a new one and try again.")
        }
        guard http.statusCode == 200,
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let login = json["login"] as? String
        else { throw UsageProviderError.http(http.statusCode) }
        return login
    }

    /// Performs an authenticated GET against the GitHub REST API with the required
    /// Accept, API-version and User-Agent headers, returning the body and HTTP response.
    private func get(_ url: String) async throws -> (Data, HTTPURLResponse) {
        var r = URLRequest(url: URL(string: url)!)
        r.timeoutInterval = 30
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        r.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        r.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        r.setValue("AgentUsage", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await URLSession.shared.data(for: r)
        guard let http = resp as? HTTPURLResponse else { throw UsageProviderError.invalidResponse }
        return (data, http)
    }
}
