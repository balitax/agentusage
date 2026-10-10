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
    let token: String

    struct Result {
        let username: String
        let used: Double
        let models: [(name: String, credits: Double)]
    }

    func creditUsage() async throws -> Result {
        let username = try await fetchUsername()
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
            // 1 AI credit = US$0.01
            let credits = unit.contains("credit") ? qty : amount * 100
            perModel[item["model"] as? String ?? "Other", default: 0] += credits
        }
        let models = perModel.sorted { $0.value > $1.value }.map { (name: $0.key, credits: $0.value) }
        return Result(username: username, used: models.reduce(0) { $0 + $1.credits }, models: models)
    }

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
