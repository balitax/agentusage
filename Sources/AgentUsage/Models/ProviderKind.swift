//
//  ProviderKind.swift
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

/// AI coding agents / platforms whose token usage can be tracked.
enum ProviderKind: String, CaseIterable, Codable, Identifiable {
    case claude, codex, copilot, gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .copilot: return "Copilot"
        case .gemini: return "Gemini"
        }
    }

    /// SF Symbol used in the provider picker.
    var symbol: String {
        switch self {
        case .claude: return "sparkles"
        case .codex: return "terminal"
        case .copilot: return "airplane"
        case .gemini: return "diamond"
        }
    }

    /// Providers that can currently be connected with a token.
    var isAvailable: Bool { self != .gemini }

    var tokenLabel: String { self == .copilot ? "GITHUB TOKEN" : "ADMIN API KEY" }

    var tokenPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-admin01-…"
        case .codex: return "sk-admin-…"
        case .copilot: return "github_pat_…"
        case .gemini: return "Coming soon"
        }
    }

    var helpText: String {
        switch self {
        case .claude:
            return
                "Needs an organization Admin key (sk-ant-admin…) from Console → Settings → Admin Keys. Subscription users: use Local logs."
        case .codex: return "platform.openai.com → Settings → Admin keys. Stored in macOS Keychain."
        case .copilot:
            return
                "GitHub → Settings → Developer settings → Fine-grained tokens. Permission: Account → Plan: Read. Personal Copilot plans only."
        case .gemini: return "This provider is not supported yet."
        }
    }

    func makeProvider(token: String) -> UsageProvider? {
        switch self {
        case .codex: return OpenAIProvider(token: token)
        case .claude, .copilot, .gemini: return nil
        }
    }
}
