//
//  StubURLProtocol.swift
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

/// A `URLProtocol` that intercepts every request made through `URLSession.shared`
/// and answers it from a test-supplied handler, so the networking providers can be
/// exercised without hitting the real APIs.
///
/// The providers build their requests against `URLSession.shared`, which consults the
/// globally registered protocol classes. `install` registers this class and stores the
/// handler; `remove` tears both down. A single `StubHTTP` scope (see below) is the
/// intended entry point and guarantees cleanup.
final class StubURLProtocol: URLProtocol {
    /// Answers a request with a response and body, or throws to simulate a transport error.
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var _handler: Handler?

    static func install(_ handler: @escaping Handler) {
        lock.lock()
        _handler = handler
        lock.unlock()
        URLProtocol.registerClass(StubURLProtocol.self)
    }

    static func remove() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        lock.lock()
        _handler = nil
        lock.unlock()
    }

    private static func currentHandler() -> Handler? {
        lock.lock()
        defer { lock.unlock() }
        return _handler
    }

    // MARK: URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { currentHandler() != nil }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.currentHandler() else {
            client?.urlProtocol(
                self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Scopes a stubbed HTTP environment for the duration of a test.
///
/// `StubHTTP` records every request it sees (useful for asserting the exact URLs and
/// headers a provider sent) and routes each one through the handler given at init.
/// Call `finish()` in `tearDown` (or use `withStub`) to unregister the protocol.
final class StubHTTP {
    /// Reads a request body even when `URLSession` has turned it into a stream.
    static func body(of request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let size = 4096
        var buffer = [UInt8](repeating: 0, count: size)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: size)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    /// Builds an `HTTPURLResponse` with a JSON body from any `Encodable`-free value tree.
    static func json(
        _ object: Any, status: Int = 200, for request: URLRequest
    ) -> (HTTPURLResponse, Data) {
        let data = try! JSONSerialization.data(withJSONObject: object)
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"])!
        return (response, data)
    }

    private let lock = NSLock()
    private var _requests: [URLRequest] = []

    /// Every request intercepted so far, in order.
    var requests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return _requests
    }

    init(_ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) {
        StubURLProtocol.install { [weak self] request in
            self?.record(request)
            return try handler(request)
        }
    }

    private func record(_ request: URLRequest) {
        lock.lock()
        _requests.append(request)
        lock.unlock()
    }

    func finish() { StubURLProtocol.remove() }
}
