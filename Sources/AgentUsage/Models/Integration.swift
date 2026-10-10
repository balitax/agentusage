//
//  Integration.swift
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

/// A connected provider account. The secret token itself lives in the Keychain, never here.
enum AuthMethod: String, Codable {
    case adminKey, oauth
}

struct Integration: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    let provider: ProviderKind
    var name: String
    var method: AuthMethod = .adminKey
    var email: String?

    init(provider: ProviderKind, name: String, method: AuthMethod = .adminKey, email: String? = nil) {
        self.provider = provider
        self.name = name
        self.method = method
        self.email = email
    }

    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        provider = try c.decode(ProviderKind.self, forKey: .provider)
        name = try c.decode(String.self, forKey: .name)
        method = try c.decodeIfPresent(AuthMethod.self, forKey: .method) ?? .adminKey
        email = try c.decodeIfPresent(String.self, forKey: .email)
    }

    var isBlankEmail: Bool { (email ?? "").isEmpty }

    private static let key = "integrations"

    static func loadAll(defaults: UserDefaults = .standard) -> [Integration] {
        guard let data = defaults.data(forKey: key),
            let list = try? JSONDecoder().decode([Integration].self, from: data)
        else { return [] }
        return list
    }

    static func saveAll(_ list: [Integration], defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(list) { defaults.set(data, forKey: key) }
    }
}
