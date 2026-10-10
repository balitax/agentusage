//
//  BrandHeader.swift
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

import SwiftUI

/// App mark plus the account switcher (avatar badge, first name, chevron).
struct BrandHeader: View {
    @EnvironmentObject var store: UsageStore
    @State private var open = false

    private var isAll: Bool { store.screen == .monthly }
    private var title: String { isAll ? "All Accounts" : firstName(store.selected.name) }
    private var letter: String { isAll ? "∑" : store.selected.initial }

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(LX.accentText)
                    .frame(width: 24, height: 24)
                    .background(RoundedRectangle(cornerRadius: 7).fill(LX.accentSoft))
                Text("Agent Usage").font(LX.font(13, .semibold)).foregroundColor(LX.text)
            }
            Spacer()
            switcher
        }
        .zIndex(1)
    }

    private var switcher: some View {
        Button {
            open.toggle()
        } label: {
            HStack(spacing: 6) {
                Badge(letter: letter)
                Text(title).font(LX.font(12, .medium)).foregroundColor(LX.text).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundColor(LX.text3)
            }
            .padding(.leading, 3).padding(.trailing, 10).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 14).fill(LX.surface))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LX.border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if open { dropdown.offset(y: 34) }
        }
    }

    private var dropdown: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(store.accounts) { a in
                item(letter: a.initial, title: a.name, selected: !isAll && a.id == store.selected.id) {
                    store.selectedID = a.id
                    store.screen = .overview
                }
            }
            if store.accounts.count > 1 {
                Hairline().padding(.vertical, 2)
                item(letter: "∑", title: "All Accounts", selected: isAll) { store.screen = .monthly }
            }
        }
        .padding(6).frame(minWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LX.border, lineWidth: 1))
    }

    private func item(letter: String, title: String, selected: Bool, action: @escaping () -> Void)
        -> some View
    {
        Button {
            open = false
            action()
        } label: {
            HStack(spacing: 8) {
                Badge(letter: letter)
                Text(title).font(LX.font(12, .medium)).foregroundColor(LX.text)
                Spacer(minLength: 12)
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .semibold))
                        .foregroundColor(LX.accentText)
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 5).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func firstName(_ full: String) -> String {
        full.split(separator: " ").first.map(String.init) ?? full
    }
}

/// One-letter badge: soft accent fill with a border.
private struct Badge: View {
    let letter: String
    var body: some View {
        Text(letter).font(LX.font(10, .semibold)).foregroundColor(LX.accentText)
            .frame(width: 20, height: 20)
            .background(Circle().fill(LX.accentSoft))
            .overlay(Circle().stroke(LX.accentLine, lineWidth: 1))
    }
}
