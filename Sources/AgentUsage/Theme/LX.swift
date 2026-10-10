//
//  LX.swift
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

import AppKit
import SwiftUI

extension Color {
    /// Color that adapts to the system appearance (light / dark mode).
    init(light: Color, dark: Color) {
        self.init(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
            })
    }
}

/// Design tokens. Every color adapts to light / dark mode.
enum LX {
    static let bg = Color(light: Color(hex: 0xFCFCFD, alpha: 0.7), dark: Color(hex: 0x1E1F22, alpha: 0.6))
    static let surface = Color(light: Color.black.opacity(0.04), dark: Color.white.opacity(0.05))
    static let surface2 = Color(light: Color.black.opacity(0.07), dark: Color.white.opacity(0.09))
    static let border = Color(light: Color.black.opacity(0.08), dark: Color.white.opacity(0.10))
    static let text = Color(light: Color(hex: 0x1D1D1F), dark: Color(hex: 0xF5F5F7))
    static let text2 = Color(light: Color.black.opacity(0.6), dark: Color.white.opacity(0.6))
    static let text3 = Color(light: Color.black.opacity(0.4), dark: Color.white.opacity(0.35))
    static let accent = Color(hex: 0x22B252)
    static let accentText = Color(light: Color(hex: 0x168038), dark: Color(hex: 0x3DD16F))
    static let accentSoft = Color(
        light: Color(hex: 0x22B252, alpha: 0.13), dark: Color(hex: 0x22B252, alpha: 0.16))
    static let accentLine = Color(
        light: Color(hex: 0x22B252, alpha: 0.55), dark: Color(hex: 0x22B252, alpha: 0.45))
    static let onAccent = Color(light: .white, dark: Color(hex: 0x04210F))
    static let danger = Color(light: Color(hex: 0xD43A2C), dark: Color(hex: 0xFF6B5E))
    static let track = Color(light: Color.black.opacity(0.06), dark: Color.white.opacity(0.08))
    static let bar = Color(light: Color.black.opacity(0.17), dark: Color.white.opacity(0.18))
    static let seg = Color(light: .white, dark: Color.white.opacity(0.12))

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
