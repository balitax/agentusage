//
//  MenuBarIcon.swift
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

/// Menu bar status icon: app mark plus two mini bars for the 5-hour and 7-day limits.
enum MenuBarIcon {
    private static let height: CGFloat = 18
    private static let logoSize: CGFloat = 12
    private static let labelWidth: CGFloat = 14
    private static let barWidth: CGFloat = 24
    private static let barHeight: CGFloat = 5
    private static let rowGap: CGFloat = 3

    /// - Parameter pending: draws empty dashed bars (loading / not set up yet).
    static func render(five: Double, seven: Double, pending: Bool = false) -> NSImage {
        let barsX = logoSize + 2 + labelWidth + 2
        let width = barsX + barWidth + 2
        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { _ in
            drawLogo()
            let topY = (height - barHeight * 2 - rowGap) / 2
            drawRow("5h", y: topY, value: five, pending: pending, barsX: barsX)
            drawRow("7d", y: topY + barHeight + rowGap, value: seven, pending: pending, barsX: barsX)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawLogo() {
        let config = NSImage.SymbolConfiguration(pointSize: logoSize, weight: .semibold)
        guard
            let symbol = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        else { return }
        let size = symbol.size
        let rect = NSRect(x: 0, y: (height - size.height) / 2, width: size.width, height: size.height)
        NSGraphicsContext.current?.saveGraphicsState()
        symbol.draw(in: rect)
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    private static func drawRow(_ label: String, y: CGFloat, value: Double, pending: Bool, barsX: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 8, weight: .medium),
            .foregroundColor: NSColor.black,
        ]
        let text = NSAttributedString(string: label, attributes: attrs)
        let size = text.size()
        let labelX = logoSize + 2 + labelWidth - size.width
        text.draw(at: NSPoint(x: labelX, y: y + (barHeight - size.height) / 2))

        let rect = NSRect(x: barsX, y: y, width: barWidth, height: barHeight)
        let track = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        if pending {
            NSColor.black.withAlphaComponent(0.25).setStroke()
            track.lineWidth = 1
            track.setLineDash([2, 2], count: 2, phase: 0)
            track.stroke()
            return
        }
        NSColor.black.withAlphaComponent(0.25).setFill()
        track.fill()
        let pct = max(0, min(1, value))
        if pct > 0 {
            let fill = NSRect(x: barsX, y: y, width: max(barHeight, barWidth * pct), height: barHeight)
            NSColor.black.setFill()
            NSBezierPath(roundedRect: fill, xRadius: 2, yRadius: 2).fill()
        }
    }
}
