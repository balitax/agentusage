//
//  LimitStepperViewModel.swift
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

/// A stepper row for a usage limit that is stored in the settings.
final class LimitStepperViewModel: ObservableObject {
    let title: String
    private let key: String
    private let step: Double
    private let minimum: Double
    private let settings: SettingsService
    private let onChange: () -> Void
    private let formatter: (Double) -> String

    @Published private(set) var value: Double

    init(
        title: String, key: String, defaultValue: Double, step: Double, minimum: Double,
        settings: SettingsService, onChange: @escaping () -> Void = {},
        formatter: @escaping (Double) -> String = { Fmt.short($0) }
    ) {
        self.title = title
        self.key = key
        self.step = step
        self.minimum = minimum
        self.settings = settings
        self.onChange = onChange
        self.formatter = formatter
        value = settings.value(forKey: key, default: defaultValue)
    }

    var text: String { formatter(value) }

    func increase() { set(value + step) }
    func decrease() { set(value - step) }

    private func set(_ newValue: Double) {
        value = max(minimum, newValue)
        settings.set(value, forKey: key)
        onChange()
    }
}
