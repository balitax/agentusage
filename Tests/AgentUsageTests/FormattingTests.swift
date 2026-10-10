//
//  FormattingTests.swift
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

final class FormattingTests: XCTestCase {
    func testTokens() {
        XCTAssertEqual(Fmt.tokens(900), "900")
        XCTAssertEqual(Fmt.tokens(128_000), "128K")
        XCTAssertEqual(Fmt.tokens(3_420_000), "3.42M")
    }

    func testShort() {
        XCTAssertEqual(Fmt.short(1_500_000), "1.5M")
        XCTAssertEqual(Fmt.short(500_000), "500K")
    }

    func testDuration() {
        XCTAssertEqual(Fmt.duration(nil), "—")
        XCTAssertEqual(Fmt.duration(0), "—")
        XCTAssertEqual(Fmt.duration(47 * 60 + 30), "47 min")
        XCTAssertEqual(Fmt.duration(3 * 3600 + 20 * 60), "3h 20m")
        XCTAssertEqual(Fmt.duration(6 * 86400 + 18 * 3600), "6d 18h")
    }

    func testUsageRangeLabels() {
        for range in UsageRange.allCases {
            XCTAssertEqual(range.labels.count, 4)
            XCTAssertEqual(range.labels.last, "Now")
        }
        XCTAssertEqual(UsageRange.d1.seconds, 86_400)
    }
}
