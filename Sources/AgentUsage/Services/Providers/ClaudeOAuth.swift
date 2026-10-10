//
//  ClaudeOAuth.swift
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

import CryptoKit
import Foundation

/// Tokens obtained from the "Sign in with Claude" flow, persisted per account.
struct OAuthCredentials: Codable, Equatable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?

    /// True when the access token is expiring within `leeway` and a refresh token exists
    /// to renew it. Non-expiring tokens (no `expiresAt`) and tokens without a refresh
    /// token never report as needing a refresh.
    func needsRefresh(leeway: TimeInterval = 300) -> Bool {
        guard refreshToken != nil, let expiresAt else { return false }
        return expiresAt <= Date().addingTimeInterval(leeway)
    }
}

/// Real utilization (0–100) reported by the Claude subscription usage endpoint.
struct RemoteUsage {
    var fiveHour: Double?
    var fiveHourReset: Date?
    var sevenDay: Double?
    var sevenDayReset: Date?
}

/// "Sign in with Claude": OAuth 2.0 authorization-code flow with PKCE (public client, no secret).
///
/// Usage: `begin()` returns a `Pending` carrying the authorize URL to open and the
/// PKCE verifier/state to hold; after the user authorizes, `exchange(input:pending:)`
/// trades the pasted `code#state` for `OAuthCredentials`. `valid(_:)` refreshes tokens
/// on demand, and `usage(_:)`/`email(_:)` read account data with a valid token.
enum ClaudeOAuth {
    /// In-flight sign-in state produced by `begin()` and consumed by `exchange`.
    struct Pending {
        /// PKCE code verifier, proven later via its SHA-256 challenge.
        let verifier: String
        /// Opaque value echoed back to bind the pasted code to this sign-in.
        let state: String
        /// The authorize URL to open in the browser.
        let url: URL
    }

    private static let clientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private static let authorizeURL = "https://claude.ai/oauth/authorize"
    private static let tokenURL = URL(string: "https://platform.claude.com/v1/oauth/token")!
    private static let redirectURI = "https://platform.claude.com/oauth/code/callback"
    private static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let userinfoURL = URL(string: "https://api.anthropic.com/api/oauth/userinfo")!
    private static let scopes = "user:profile user:inference"

    // MARK: Flow

    /// Starts a sign-in: generates a fresh PKCE verifier and state and builds the
    /// authorize URL. The returned `Pending` must be kept until `exchange`.
    static func begin() -> Pending {
        let verifier = randomString()
        let state = randomString()
        // PKCE S256: the challenge sent now is the SHA-256 of the verifier revealed at exchange.
        let challenge = base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
        var c = URLComponents(string: authorizeURL)!
        c.queryItems = [
            .init(name: "code", value: "true"),
            .init(name: "client_id", value: clientId),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: redirectURI),
            .init(name: "scope", value: scopes),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "state", value: state),
        ]
        return Pending(verifier: verifier, state: state, url: c.url!)
    }

    /// Exchanges the pasted authorization result for tokens.
    ///
    /// - Parameters:
    ///   - input: What the browser shows after authorizing, formatted `code#state`.
    ///   - pending: The `Pending` returned by the matching `begin()` call.
    /// - Throws: `UsageProviderError.message` when the code is missing or its state
    ///   doesn't match `pending` (guards against a stale/wrong sign-in), and
    ///   `.invalidResponse` when the token response lacks an access token.
    static func exchange(input: String, pending: Pending) async throws -> OAuthCredentials {
        let parts = input.trimmingCharacters(in: .whitespacesAndNewlines).split(
            separator: "#", maxSplits: 1)
        guard let code = parts.first.map(String.init), !code.isEmpty else {
            throw UsageProviderError.message("Paste the code shown after you authorize.")
        }
        // The returned state must equal the one we generated, or this isn't our sign-in.
        guard parts.count > 1, String(parts[1]) == pending.state else {
            throw UsageProviderError.message("The code doesn't match this sign-in. Start again.")
        }
        let json = try await tokenRequest([
            "grant_type": "authorization_code", "code": code, "state": pending.state,
            "client_id": clientId, "redirect_uri": redirectURI, "code_verifier": pending.verifier,
        ])
        guard let creds = credentials(from: json, fallback: nil) else {
            throw UsageProviderError.invalidResponse
        }
        return creds
    }

    /// Returns credentials guaranteed to be usable now: `c` unchanged when it isn't due
    /// for refresh, otherwise freshly refreshed tokens. The caller should persist the
    /// result, since the access (and possibly refresh) token may have changed.
    static func valid(_ c: OAuthCredentials) async throws -> OAuthCredentials {
        guard c.needsRefresh(), let refresh = c.refreshToken else { return c }
        let json = try await tokenRequest([
            "grant_type": "refresh_token", "refresh_token": refresh, "client_id": clientId,
        ])
        guard let fresh = credentials(from: json, fallback: c) else {
            throw UsageProviderError.invalidResponse
        }
        return fresh
    }

    // MARK: Data

    /// Fetches the subscription's 5-hour and 7-day utilization windows.
    ///
    /// - Throws: `UsageProviderError.message` for an expired session (401/403) or rate
    ///   limiting (429), and `.http` for other non-200 responses.
    static func usage(_ c: OAuthCredentials) async throws -> RemoteUsage {
        let (data, http) = try await authorized(usageURL, c)
        if http.statusCode == 401 || http.statusCode == 403 {
            throw UsageProviderError.message(
                "Claude session expired. Edit this integration and sign in again.")
        }
        if http.statusCode == 429 { throw UsageProviderError.message("Rate limited by Claude. Will retry.") }
        guard http.statusCode == 200, let j = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw UsageProviderError.http(http.statusCode) }
        func bucket(_ key: String) -> (Double?, Date?) {
            guard let b = j[key] as? [String: Any] else { return (nil, nil) }
            return ((b["utilization"] as? NSNumber)?.doubleValue, date(b["resets_at"] as? String))
        }
        let five = bucket("five_hour")
        let seven = bucket("seven_day")
        return RemoteUsage(fiveHour: five.0, fiveHourReset: five.1, sevenDay: seven.0, sevenDayReset: seven.1)
    }

    /// Best-effort lookup of the account's email (falling back to its display name).
    /// Returns `nil` on any failure, since the label is cosmetic.
    static func email(_ c: OAuthCredentials) async -> String? {
        guard let (data, http) = try? await authorized(userinfoURL, c), http.statusCode == 200,
            let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (j["email"] as? String) ?? (j["name"] as? String)
    }

    // MARK: Helpers

    /// Performs a bearer-authenticated GET with the anthropic-beta OAuth header.
    private static func authorized(_ url: URL, _ c: OAuthCredentials) async throws -> (Data, HTTPURLResponse)
    {
        var r = URLRequest(url: url)
        r.timeoutInterval = 30
        r.setValue("Bearer \(c.accessToken)", forHTTPHeaderField: "Authorization")
        r.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        let (data, resp) = try await URLSession.shared.data(for: r)
        guard let http = resp as? HTTPURLResponse else { throw UsageProviderError.invalidResponse }
        return (data, http)
    }

    /// POSTs a JSON body to the token endpoint and returns the decoded response,
    /// mapping any non-200 into a `UsageProviderError.message` that includes a snippet
    /// of the server's reply. Used for both the code and refresh grants.
    private static func tokenRequest(_ body: [String: String]) async throws -> [String: Any] {
        var r = URLRequest(url: tokenURL)
        r.httpMethod = "POST"
        r.timeoutInterval = 30
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: r)
        guard let http = resp as? HTTPURLResponse else { throw UsageProviderError.invalidResponse }
        guard http.statusCode == 200, let j = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw UsageProviderError.message("Sign-in failed (HTTP \(http.statusCode)). \(text.prefix(120))")
        }
        return j
    }

    /// Builds credentials from a token response, carrying over the `fallback`'s refresh
    /// token and expiry when a refresh response omits them. Returns `nil` without an
    /// access token.
    private static func credentials(from j: [String: Any], fallback: OAuthCredentials?) -> OAuthCredentials? {
        guard let token = j["access_token"] as? String, !token.isEmpty else { return nil }
        let expires = (j["expires_in"] as? NSNumber).map { Date().addingTimeInterval($0.doubleValue) }
        return OAuthCredentials(
            accessToken: token, refreshToken: (j["refresh_token"] as? String) ?? fallback?.refreshToken,
            expiresAt: expires ?? fallback?.expiresAt)
    }

    /// Parses an ISO-8601 timestamp, tolerating both fractional-second and plain forms.
    private static func date(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }

    /// 32 bytes of CSPRNG output, base64url-encoded — used for the PKCE verifier and state.
    private static func randomString() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URL(Data(bytes))
    }

    /// Base64url encoding (RFC 4648 §5): URL-safe alphabet, no padding, as OAuth/PKCE require.
    private static func base64URL(_ d: Data) -> String {
        d.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
