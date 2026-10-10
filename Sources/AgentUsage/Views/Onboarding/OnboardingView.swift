//
//  OnboardingView.swift
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

/// First-launch walkthrough: welcome → choose source → ready.
struct OnboardingView: View {
    @EnvironmentObject var store: UsageStore
    @State private var useLocal = true

    private var localFound: Bool { store.accounts.contains { $0.integrationID == nil } }

    var body: some View {
        VStack(spacing: 20) {
            switch store.onboardingStep {
            case 0: welcome
            case 1: chooseSource
            default: ready
            }
            StepDots(current: store.onboardingStep)
        }
        .onAppear { useLocal = localFound }
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 20) {
            Badge(symbol: "sparkles")
            titleBlock("Agent Usage", "Your AI coding limits, always one glance away in the menu bar.", 28)
            VStack(alignment: .leading, spacing: 16) {
                OptionRow(
                    symbol: "gauge.medium", title: "Live limits",
                    subtitle: "5-hour and 7-day windows with reset times.")
                OptionRow(
                    symbol: "person.2", title: "Many accounts",
                    subtitle: "Personal, work and side projects in one place.")
                OptionRow(
                    symbol: "lock", title: "Private by design",
                    subtitle: "Tokens stay in your macOS Keychain.")
            }.padding(.vertical, 4)
            primary("Get started", symbol: "arrow.right") { store.onboardingStep = 1 }
        }
    }

    private var chooseSource: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Connect your agents").font(LX.font(20, .semibold)).foregroundColor(LX.text)
                Text("Pick how Agent Usage should read your usage. You can add more later.")
                    .font(LX.font(13)).foregroundColor(LX.text2).fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 10) {
                Button {
                    useLocal = true
                } label: {
                    OptionRow(
                        symbol: "folder.badge.checkmark", title: "Local logs",
                        subtitle: localFound
                            ? "Claude Code detected in ~/.claude. No sign-in needed."
                            : "Claude Code not found on this Mac.",
                        card: true, selected: useLocal && localFound, trailing: "checkmark.circle")
                }.buttonStyle(.plain).disabled(!localFound)
                Button {
                    store.screen = .addIntegration
                } label: {
                    OptionRow(
                        symbol: "arrow.right.circle", title: "Sign in or API key",
                        subtitle: "Sign in with Claude, or add an OpenAI Admin key.", card: true,
                        selected: !useLocal, trailing: "chevron.right")
                }.buttonStyle(.plain)
                OptionRow(
                    symbol: "bubbles.and.sparkles", title: "Copilot · Gemini",
                    subtitle: "Support is coming soon.", card: true
                ).opacity(0.45)
            }
            primary("Continue", symbol: "arrow.right") {
                if localFound && useLocal { store.onboardingStep = 2 } else { store.screen = .addIntegration }
            }
            Button("Back") { store.onboardingStep = 0 }
                .buttonStyle(.plain).font(LX.font(12)).foregroundColor(LX.text2).frame(maxWidth: .infinity)
        }
    }

    private var ready: some View {
        VStack(spacing: 20) {
            Badge(symbol: "checkmark")
            titleBlock(
                "You're all set",
                "Reading usage from \(store.accounts.count) source\(store.accounts.count == 1 ? "" : "s"). Refreshes every minute.",
                24)
            VStack(spacing: 12) {
                ForEach(store.accounts) { IntegrationRow(account: $0) }
                if store.accounts.isEmpty {
                    Text("Nothing connected. Add one from Accounts anytime.")
                        .font(LX.font(11)).foregroundColor(LX.text3)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(LX.surface))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LX.border, lineWidth: 1))
            Label("Find the % in your menu bar. Click it anytime.", systemImage: "info.circle")
                .font(LX.font(11)).foregroundColor(LX.text3)
            primary("Open dashboard", symbol: "square.grid.2x2") { store.finishOnboarding() }
        }
    }

    // MARK: Pieces

    private func titleBlock(_ title: String, _ sub: String, _ size: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(title).font(LX.font(size, .semibold)).foregroundColor(LX.text)
            Text(sub).font(LX.font(13)).foregroundColor(LX.text2).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primary(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                Text(title)
            }
        }.buttonStyle(PrimaryButtonStyle())
    }
}

private struct Badge: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol).font(.system(size: 26)).foregroundColor(LX.accentText)
            .frame(width: 64, height: 64).background(Circle().fill(LX.accentSoft))
    }
}

private struct OptionRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    var card = false
    var selected = false
    var trailing: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 15))
                .foregroundColor(selected || !card ? LX.accentText : LX.text2)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(selected || !card ? LX.accentSoft : LX.surface2))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(LX.font(13, .semibold)).foregroundColor(LX.text)
                Text(subtitle).font(LX.font(12)).foregroundColor(LX.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let trailing {
                Image(systemName: trailing).font(.system(size: 14))
                    .foregroundColor(selected ? LX.accentText : LX.text3)
            }
        }
        .padding(card ? 14 : 0)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(card ? (selected ? LX.accentSoft : LX.surface) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(
                card ? (selected ? LX.accentLine : LX.border) : .clear, lineWidth: 1))
    }
}

private struct StepDots: View {
    let current: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule().fill(i == current ? LX.accent : LX.bar).frame(
                    width: i == current ? 20 : 6, height: 6)
            }
        }
    }
}
