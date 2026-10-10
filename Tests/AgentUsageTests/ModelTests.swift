//
//  ModelTests.swift
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

final class ModelTests: XCTestCase {
    func testIntegrationDecodesLegacyJSONWithoutMethod() throws {
        let json = #"{"id":"1","provider":"codex","name":"Work"}"#.data(using: .utf8)!
        let item = try JSONDecoder().decode(Integration.self, from: json)
        XCTAssertEqual(item.method, .adminKey)
        XCTAssertNil(item.email)
    }

    func testIntegrationPersistenceRoundTrip() {
        let d = TestSupport.defaults()
        let item = Integration(provider: .copilot, name: "me", email: "octocat")
        Integration.saveAll([item], defaults: d)
        let loaded = Integration.loadAll(defaults: d)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.provider, .copilot)
        XCTAssertEqual(loaded.first?.email, "octocat")
    }

    func testProviderAvailability() {
        XCTAssertTrue(ProviderKind.claude.isAvailable)
        XCTAssertTrue(ProviderKind.copilot.isAvailable)
        XCTAssertFalse(ProviderKind.gemini.isAvailable)
    }

    func testProviderFactories() {
        XCTAssertNil(ProviderKind.claude.makeProvider(token: "x"))
        XCTAssertNotNil(ProviderKind.codex.makeProvider(token: "x"))
        XCTAssertEqual(ProviderKind.copilot.tokenLabel, "GITHUB TOKEN")
    }

    func testRouterNavigation() {
        XCTAssertEqual(Router(onboarded: false).screen, .onboarding)
        let router = Router(onboarded: true)
        XCTAssertEqual(router.screen, .overview)
        router.edit("abc")
        XCTAssertEqual(router.screen, .addIntegration)
        XCTAssertEqual(router.editingID, "abc")
        router.addIntegration()
        XCTAssertNil(router.editingID)
    }

    func testSettingsPersistence() {
        let d = TestSupport.defaults()
        let a = SettingsService(defaults: d)
        XCTAssertFalse(a.showHighest)
        XCTAssertFalse(a.onboarded)
        a.showHighest = true
        a.onboarded = true
        a.set(42, forKey: "k")

        let b = SettingsService(defaults: d)
        XCTAssertTrue(b.showHighest)
        XCTAssertTrue(b.onboarded)
        XCTAssertEqual(b.value(forKey: "k", default: 1), 42)
        XCTAssertEqual(b.value(forKey: "missing", default: 7), 7)
    }
}
