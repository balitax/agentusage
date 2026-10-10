//
//  UsageProvider.swift
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

/// A source of token usage events, e.g. a vendor usage API.
protocol UsageProvider {
    func events(since: Date) async throws -> [UsageEvent]
}

enum UsageProviderError: LocalizedError {
    case unauthorized(String?)
    case wrongKeyType(String)
    case message(String)
    case http(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized(let detail):
            let base =
                "Key rejected. This needs an Admin key from an organization (not a personal or subscription key)."
            return detail.map { "\(base) Server said: \($0)" } ?? base
        case .wrongKeyType(let msg), .message(let msg): return msg
        case .http(let code): return "Request failed (HTTP \(code))."
        case .invalidResponse: return "Unexpected response from provider."
        }
    }
}
