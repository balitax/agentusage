//
//  BrandHeaderViewModel.swift
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

/// Account switcher shown in the header of the overview and monthly screens.
final class BrandHeaderViewModel: BaseViewModel {
    private let app: AppViewModel

    init(app: AppViewModel) {
        self.app = app
        super.init()
        forward(app)
    }

    var accounts: [Account] { app.accounts }
    var isAllAccounts: Bool { app.router.screen == .monthly }
    var canShowAll: Bool { accounts.count > 1 }
    var letter: String { isAllAccounts ? "∑" : app.selected.initial }

    /// Switcher label: first name of the account, or "All Accounts".
    var title: String {
        guard !isAllAccounts else { return "All Accounts" }
        let name = app.selected.name
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    func isSelected(_ account: Account) -> Bool {
        !isAllAccounts && account.id == app.selected.id
    }

    func select(_ account: Account) { app.select(account) }
    func showAll() { app.router.go(.monthly) }
}
