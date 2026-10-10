//
//  ProviderTests.swift
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

import XCTest

@testable import AgentUsage

final class ProviderTests: XCTestCase {
    private var http: StubHTTP?

    override func tearDown() {
        http?.finish()
        http = nil
        super.tearDown()
    }

    /// Installs a stub that routes by the request URL and records every request.
    @discardableResult
    private func stub(_ route: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) -> StubHTTP {
        let stub = StubHTTP(route)
        http = stub
        return stub
    }

    private func path(_ request: URLRequest) -> String { request.url?.path ?? "" }
    private func host(_ request: URLRequest) -> String { request.url?.host ?? "" }

    /// Fails unless the block throws a `UsageProviderError` the matcher approves of.
    private func expectProviderError(
        _ matches: @escaping (UsageProviderError) -> Bool,
        file: StaticString = #filePath, line: UInt = #line, _ block: () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("Expected a UsageProviderError to be thrown", file: file, line: line)
        } catch let error as UsageProviderError {
            XCTAssertTrue(matches(error), "Unexpected error: \(error)", file: file, line: line)
        } catch {
            XCTFail("Expected a UsageProviderError, got \(error)", file: file, line: line)
        }
    }

    // MARK: BucketClient

    func testBucketClientFollowsPagination() async throws {
        let stub = stub { request in
            let onPageTwo = request.url?.query?.contains("page=P2") == true
            let body: [String: Any] =
                onPageTwo
                ? ["data": [["id": 2]], "has_more": false]
                : ["data": [["id": 1]], "has_more": true, "next_page": "P2"]
            return StubHTTP.json(body, for: request)
        }

        let buckets = try await BucketClient.fetch(
            base: "https://example.com/usage", query: [.init(name: "limit", value: "10")], headers: [:])

        XCTAssertEqual(buckets.count, 2)
        XCTAssertEqual(buckets.map { BucketClient.int($0["id"]) }, [1, 2])
        XCTAssertEqual(stub.requests.count, 2)
        XCTAssertEqual(stub.requests.first?.url?.query?.contains("page"), false)
        XCTAssertTrue(stub.requests.last?.url?.query?.contains("page=P2") == true)
    }

    func testBucketClientSendsHeadersAndStopsWithoutHasMore() async throws {
        let stub = stub { request in
            StubHTTP.json(["data": [["id": 1]], "has_more": false], for: request)
        }

        let buckets = try await BucketClient.fetch(
            base: "https://example.com/usage", query: [], headers: ["Authorization": "Bearer k"])

        XCTAssertEqual(buckets.count, 1)
        XCTAssertEqual(stub.requests.count, 1)
        XCTAssertEqual(
            stub.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer k")
    }

    func testBucketClientMapsUnauthorizedToDetailedError() async {
        stub { request in
            StubHTTP.json(["error": ["message": "bad key"]], status: 401, for: request)
        }

        await expectProviderError({
            if case .unauthorized(let detail) = $0 { return detail == "bad key" }
            return false
        }) {
            _ = try await BucketClient.fetch(base: "https://example.com/u", query: [], headers: [:])
        }
    }

    func testBucketClientMapsServerErrorToHTTP() async {
        stub { request in StubHTTP.json([:], status: 500, for: request) }

        await expectProviderError({
            if case .http(let code) = $0 { return code == 500 }
            return false
        }) {
            _ = try await BucketClient.fetch(base: "https://example.com/u", query: [], headers: [:])
        }
    }

    // MARK: OpenAIProvider

    func testOpenAIProviderBuildsEventsAndDropsEmptyBuckets() async throws {
        let stub = stub { request in
            let body: [String: Any] = [
                "data": [
                    [
                        "start_time": 1_700_000_000,
                        "results": [["input_tokens": 10, "output_tokens": 5]],
                    ],
                    ["start_time": 1_700_003_600, "results": [["input_tokens": 0, "output_tokens": 0]]],
                ],
                "has_more": false,
            ]
            return StubHTTP.json(body, for: request)
        }

        let provider = OpenAIProvider(token: "sk-test")
        let events = try await provider.events(since: Date().addingTimeInterval(-86400))

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.tokens, 15)
        XCTAssertEqual(
            stub.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
        XCTAssertEqual(host(stub.requests.first!), "api.openai.com")
    }

    // MARK: CopilotProvider

    func testCopilotProviderAggregatesCreditsPerModel() async throws {
        stub { request in
            if self.path(request).contains("ai_credit") {
                let body: [String: Any] = [
                    "usageItems": [
                        ["model": "gpt-4.1", "unitType": "ai_credit", "grossQuantity": 100],
                        ["model": "claude", "unitType": "usd", "grossAmount": 2.5],
                        ["model": "gpt-4.1", "unitType": "ai_credit", "grossQuantity": 50],
                    ]
                ]
                return StubHTTP.json(body, for: request)
            }
            return StubHTTP.json(["login": "octocat"], for: request)
        }

        let result = try await CopilotProvider(token: "ghp_test").creditUsage()

        XCTAssertEqual(result.username, "octocat")
        XCTAssertEqual(result.used, 400, accuracy: 0.0001)
        XCTAssertEqual(result.models.map { $0.name }, ["claude", "gpt-4.1"])
        XCTAssertEqual(result.models.first?.credits ?? 0, 250, accuracy: 0.0001)
        XCTAssertEqual(result.models.last?.credits ?? 0, 150, accuracy: 0.0001)
    }

    func testCopilotProviderSurfacesRejectedToken() async {
        stub { request in StubHTTP.json([:], status: 401, for: request) }

        await expectProviderError({
            if case .message(let m) = $0 { return m.contains("rejected this token") }
            return false
        }) {
            _ = try await CopilotProvider(token: "bad").creditUsage()
        }
    }

    func testCopilotProviderExplainsMissingPermission() async {
        stub { request in
            if self.path(request).contains("ai_credit") {
                return StubHTTP.json([:], status: 403, for: request)
            }
            return StubHTTP.json(["login": "octocat"], for: request)
        }

        await expectProviderError({
            if case .message(let m) = $0 { return m.contains("Plan: Read") }
            return false
        }) {
            _ = try await CopilotProvider(token: "ghp").creditUsage()
        }
    }

    func testCopilotProviderExplainsNoPersonalBilling() async {
        stub { request in
            if self.path(request).contains("ai_credit") {
                return StubHTTP.json([:], status: 404, for: request)
            }
            return StubHTTP.json(["login": "octocat"], for: request)
        }

        await expectProviderError({
            if case .message(let m) = $0 { return m.contains("No personal Copilot billing") }
            return false
        }) {
            _ = try await CopilotProvider(token: "ghp").creditUsage()
        }
    }

    // MARK: ClaudeOAuth

    func testClaudeExchangeReturnsCredentials() async throws {
        stub { request in
            StubHTTP.json(
                ["access_token": "tok", "refresh_token": "ref", "expires_in": 3600], for: request)
        }

        let pending = ClaudeOAuth.begin()
        let creds = try await ClaudeOAuth.exchange(input: "the-code#\(pending.state)", pending: pending)

        XCTAssertEqual(creds.accessToken, "tok")
        XCTAssertEqual(creds.refreshToken, "ref")
        XCTAssertNotNil(creds.expiresAt)
    }

    func testClaudeExchangeRejectsMismatchedState() async {
        stub { request in StubHTTP.json([:], for: request) }
        let pending = ClaudeOAuth.begin()

        await expectProviderError({
            if case .message(let m) = $0 { return m.contains("doesn't match") }
            return false
        }) {
            _ = try await ClaudeOAuth.exchange(input: "code#wrong-state", pending: pending)
        }
        XCTAssertTrue(http?.requests.isEmpty == true, "A mismatched state must not hit the network")
    }

    func testClaudeValidSkipsRefreshWhenFresh() async throws {
        stub { request in StubHTTP.json([:], status: 500, for: request) }
        let creds = OAuthCredentials(
            accessToken: "tok", refreshToken: "ref", expiresAt: Date().addingTimeInterval(3600))

        let same = try await ClaudeOAuth.valid(creds)

        XCTAssertEqual(same, creds)
        XCTAssertTrue(http?.requests.isEmpty == true, "A fresh token must not be refreshed")
    }

    func testClaudeValidRefreshesExpiredToken() async throws {
        stub { request in
            StubHTTP.json(["access_token": "fresh", "expires_in": 3600], for: request)
        }
        let creds = OAuthCredentials(
            accessToken: "stale", refreshToken: "ref", expiresAt: Date().addingTimeInterval(-10))

        let refreshed = try await ClaudeOAuth.valid(creds)

        XCTAssertEqual(refreshed.accessToken, "fresh")
        XCTAssertEqual(refreshed.refreshToken, "ref", "Refresh token carries over when not re-issued")
    }

    func testClaudeUsageParsesUtilizationBuckets() async throws {
        let stub = stub { request in
            let body: [String: Any] = [
                "five_hour": ["utilization": 42, "resets_at": "2026-10-10T12:00:00Z"],
                "seven_day": ["utilization": 27],
            ]
            return StubHTTP.json(body, for: request)
        }

        let usage = try await ClaudeOAuth.usage(
            OAuthCredentials(accessToken: "tok", refreshToken: nil, expiresAt: nil))

        XCTAssertEqual(usage.fiveHour, 42)
        XCTAssertEqual(usage.sevenDay, 27)
        XCTAssertNotNil(usage.fiveHourReset)
        XCTAssertNil(usage.sevenDayReset)
        XCTAssertEqual(
            stub.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer tok")
        XCTAssertEqual(
            stub.requests.first?.value(forHTTPHeaderField: "anthropic-beta"), "oauth-2025-04-20")
    }

    func testClaudeUsageMapsExpiredSessionTo401() async {
        stub { request in StubHTTP.json([:], status: 401, for: request) }

        await expectProviderError({
            if case .message(let m) = $0 { return m.contains("session expired") }
            return false
        }) {
            _ = try await ClaudeOAuth.usage(
                OAuthCredentials(accessToken: "tok", refreshToken: nil, expiresAt: nil))
        }
    }

    func testClaudeEmailReturnsNilOnFailure() async {
        stub { request in StubHTTP.json([:], status: 500, for: request) }

        let email = await ClaudeOAuth.email(
            OAuthCredentials(accessToken: "tok", refreshToken: nil, expiresAt: nil))

        XCTAssertNil(email)
    }

    func testClaudeEmailReadsAddress() async {
        stub { request in StubHTTP.json(["email": "dev@example.com"], for: request) }

        let email = await ClaudeOAuth.email(
            OAuthCredentials(accessToken: "tok", refreshToken: nil, expiresAt: nil))

        XCTAssertEqual(email, "dev@example.com")
    }
}
