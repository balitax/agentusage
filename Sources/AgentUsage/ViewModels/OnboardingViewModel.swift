//
//  OnboardingViewModel.swift
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

/// First-launch walkthrough: welcome, choose source, ready.
final class OnboardingViewModel: BaseViewModel {
    private let app: AppViewModel
    @Published var useLocal = true

    init(app: AppViewModel) {
        self.app = app
        super.init()
        forward(app)
        useLocal = localFound
    }

    var step: Int { app.router.onboardingStep }
    var accounts: [Account] { app.accounts }
    var localFound: Bool { accounts.contains { $0.integrationID == nil } }
    var sourceCount: Int { accounts.count }

    var readySubtitle: String {
        "Reading usage from \(sourceCount) source\(sourceCount == 1 ? "" : "s"). Refreshes every minute."
    }

    func onAppear() { useLocal = localFound }

    func start() { app.router.onboardingStep = 1 }
    func back() { app.router.onboardingStep = 0 }
    func chooseLocal() { useLocal = true }
    func chooseToken() { app.router.addIntegration() }

    func continueFromSource() {
        if localFound && useLocal {
            app.router.onboardingStep = 2
        } else {
            app.router.addIntegration()
        }
    }

    func finish() { app.finishOnboarding() }
}
