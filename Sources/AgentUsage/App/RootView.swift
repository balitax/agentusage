//
//  RootView.swift
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

/// Switches between screens. View models are created lazily, once per appearance of a screen.
struct RootView: View {
    let container: AppContainer
    @ObservedObject var app: AppViewModel

    var body: some View {
        Group {
            switch app.router.screen {
            case .overview: OverviewView(viewModel: container.makeOverview())
            case .accounts: AccountsView(viewModel: container.makeAccounts())
            case .monthly: MonthlyView(viewModel: container.makeMonthly())
            case .addIntegration: AddIntegrationView(viewModel: container.makeAddIntegration())
            case .onboarding: OnboardingView(viewModel: container.makeOnboarding())
            }
        }
        .padding(app.router.screen == .onboarding ? 24 : 20)
        .frame(width: 360)
        .background(PopoverBackground())
    }
}
